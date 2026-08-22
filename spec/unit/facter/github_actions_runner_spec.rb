# frozen_string_literal: true

require 'spec_helper'

describe 'github_actions_runner fact' do
  def fact_value
    Facter.clear
    allow(Facter[:kernel]).to receive(:value).and_return('Linux')
    load File.expand_path('../../../lib/facter/github_actions_runner.rb', __dir__)
    Facter.value(:github_actions_runner)
  end

  after { Facter.clear }

  it 'returns directories containing both runner state files as instances' do
    allow(Dir).to receive(:glob)
      .with('{/etc,/usr/lib,/lib}/systemd/system/github-actions-runner.*.service')
      .and_return(['/etc/systemd/system/github-actions-runner.custom.service'])
    allow(Dir).to receive(:glob)
      .with('/opt/actions-runner{,-*}/*')
      .and_return(['/opt/actions-runner-1/unconfigured'])
    allow(File).to receive(:readlines)
      .with('/etc/systemd/system/github-actions-runner.custom.service', chomp: true)
      .and_return(['[Service]', 'WorkingDirectory=/srv/runners/custom'])
    allow(File).to receive(:file?) do |path|
      ['/srv/runners/custom/.credentials', '/srv/runners/custom/.path'].include?(path)
    end

    expect(fact_value).to eq('instances' => ['/srv/runners/custom'])
  end

  it 'requires both credentials and path files' do
    allow(Dir).to receive(:glob)
      .with('{/etc,/usr/lib,/lib}/systemd/system/github-actions-runner.*.service')
      .and_return([])
    allow(Dir).to receive(:glob)
      .with('/opt/actions-runner{,-*}/*')
      .and_return(['/opt/actions-runner-1/incomplete'])
    allow(File).to receive(:file?) do |path|
      path == '/opt/actions-runner-1/incomplete/.credentials'
    end

    expect(fact_value).to eq('instances' => [])
  end
end
