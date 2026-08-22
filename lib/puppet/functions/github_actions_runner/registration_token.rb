# frozen_string_literal: true

require 'base64'
require 'json'
require 'net/http'
require 'openssl'
require 'uri'

# @summary Generate a runner registration token with a GitHub App on the Puppet server.
Puppet::Functions.create_function(:'github_actions_runner::registration_token') do
  # @param app_id Numeric ID of the GitHub App.
  # @param installation_id Numeric ID of the GitHub App installation.
  # @param private_key App PEM private key supplied as a Sensitive value.
  # @param github_api Base URL for the GitHub API.
  # @param token_url GitHub API endpoint that creates the runner registration token.
  # @return [String] A short-lived runner registration token.
  dispatch :registration_token do
    param 'Integer[1]', :app_id
    param 'Integer[1]', :installation_id
    param 'Sensitive[String[1]]', :private_key
    param 'String[1]', :github_api
    param 'String[1]', :token_url
    return_type 'String[1]'
  end

  def registration_token(app_id, installation_id, private_key, github_api, token_url)
    app_jwt = encode_jwt(app_id, private_key)
    installation_url = "#{github_api.chomp('/')}/app/installations/#{installation_id}/access_tokens"
    installation_token = request_token(installation_url, app_jwt)

    request_token(token_url, installation_token)
  rescue OpenSSL::PKey::PKeyError => e
    raise Puppet::Error, "Unable to load GitHub App private key: #{e.message}"
  end

  def encode_jwt(app_id, private_key)
    now = Time.now.to_i
    payload = {
      iat: now - 60,
      exp: now + 540,
      iss: app_id.to_s,
    }
    signing_key = OpenSSL::PKey::RSA.new(private_key.unwrap)
    header = { alg: 'RS256', typ: 'JWT' }
    signing_input = [header, payload].map { |part| base64url(JSON.generate(part)) }.join('.')
    signature = signing_key.sign(OpenSSL::Digest.new('SHA256'), signing_input)

    "#{signing_input}.#{base64url(signature)}"
  end

  def base64url(value)
    Base64.urlsafe_encode64(value, padding: false)
  end

  def request_token(url, bearer_token)
    uri = URI(url)
    request = Net::HTTP::Post.new(uri)
    request['Accept'] = 'application/vnd.github+json'
    request['Authorization'] = "Bearer #{bearer_token}"

    response = Net::HTTP::Proxy(:ENV).start(uri.hostname, uri.port, use_ssl: uri.scheme == 'https') do |http|
      http.request(request)
    end
    raise Puppet::Error, "GitHub token request to '#{uri}' failed: HTTP #{response.code} #{response.message}" unless response.is_a?(Net::HTTPSuccess)

    JSON.parse(response.body).fetch('token')
  rescue JSON::ParserError, KeyError => e
    raise Puppet::Error, "GitHub token response from '#{uri}' did not contain a valid token: #{e.message}"
  end
end
