# frozen_string_literal: true

require 'spec_helper'
require 'base64'
require 'json'
require 'net/http'
require 'openssl'

describe 'github_actions_runner::registration_token' do
  let(:key_material) do
    key = OpenSSL::PKey::RSA.generate(2048)
    private_key = Puppet::Pops::Types::PSensitiveType::Sensitive.new(key.to_pem)
    { key: key, private_key: private_key }
  end
  let(:requests) { [] }
  let(:http) { instance_double(Net::HTTP) }
  let(:http_proxy) { class_double(Net::HTTP) }

  def successful_response(body)
    Net::HTTPCreated.new('1.1', '201', 'Created').tap do |response|
      response.body = body
      response.instance_variable_set(:@read, true)
    end
  end

  before do
    installation_response = successful_response('{"token":"installation-token"}')
    registration_response = successful_response('{"token":"runner-token"}')

    allow(Net::HTTP).to receive(:Proxy).with(:ENV).and_return(http_proxy)
    allow(http_proxy).to receive(:start).and_yield(http)
    allow(http).to receive(:request) do |request|
      requests << request
      requests.one? ? installation_response : registration_response
    end
  end

  it 'returns the runner registration token' do
    token = subject.execute(
      12_345,
      67_890,
      key_material[:private_key],
      'https://api.github.com',
      'https://api.github.com/orgs/example/actions/runners/registration-token',
    )

    expect(token).to eq('runner-token')
  end

  it 'authenticates the installation request with an RS256 App JWT' do
    subject.execute(
      12_345,
      67_890,
      key_material[:private_key],
      'https://api.github.com',
      'https://api.github.com/orgs/example/actions/runners/registration-token',
    )

    request = requests.first
    app_jwt = request['Authorization'].delete_prefix('Bearer ')
    encoded_header, encoded_payload, encoded_signature = app_jwt.split('.')
    header = JSON.parse(Base64.urlsafe_decode64(encoded_header))
    payload = JSON.parse(Base64.urlsafe_decode64(encoded_payload))
    signature = Base64.urlsafe_decode64(encoded_signature)

    expect(header).to eq('alg' => 'RS256', 'typ' => 'JWT')
    expect(key_material[:key].public_key.verify(OpenSSL::Digest.new('SHA256'), signature, "#{encoded_header}.#{encoded_payload}")).to be(true)
    expect(payload['iss']).to eq('12345')
  end

  it 'raises a useful error when the key is invalid' do
    invalid_key = Puppet::Pops::Types::PSensitiveType::Sensitive.new('not a PEM private key')

    expect do
      subject.execute(
        12_345,
        67_890,
        invalid_key,
        'https://api.github.com',
        'https://api.github.com/orgs/example/actions/runners/registration-token',
      )
    end.to raise_error(Puppet::Error, %r{Unable to load GitHub App private key})
  end
end
