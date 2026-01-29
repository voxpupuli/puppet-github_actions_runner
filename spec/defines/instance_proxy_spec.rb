# frozen_string_literal: true

require 'spec_helper'

describe 'github_actions_runner::instance' do
  let(:title) { 'test_runner' }
  let(:pre_condition) do
    <<-PUPPET
    class { 'github_actions_runner':
      org_name => 'test_org',
      personal_access_token => 'PAT',
    }
    PUPPET
  end

  on_supported_os.each do |os, os_facts|
    context "on #{os}" do
      let(:facts) { os_facts }

      let(:params) do
        {
          'org_name' => 'test_org',
          'repo_name' => 'test_repo',
          'labels' => %w[test_label1 test_label2],
        }
      end

      describe 'proxy configuration with PAT authentication' do
        let(:params) do
          super().merge(
            'http_proxy' => 'http://proxy.local:8080',
            'https_proxy' => 'https://proxy.local:8443',
            'no_proxy' => 'localhost,example.com'
          )
        end

        it 'exports http_proxy environment variable' do
          is_expected.to contain_file("/opt/actions-runner-#{RUNNER_VERSION}/test_runner/configure_install_runner.sh").
            with_content(%r{export http_proxy="http://proxy.local:8080"})
        end

        it 'exports https_proxy environment variable' do
          is_expected.to contain_file("/opt/actions-runner-#{RUNNER_VERSION}/test_runner/configure_install_runner.sh").
            with_content(%r{export https_proxy="https://proxy.local:8443"})
        end

        it 'exports no_proxy environment variable' do
          is_expected.to contain_file("/opt/actions-runner-#{RUNNER_VERSION}/test_runner/configure_install_runner.sh").
            with_content(%r{export no_proxy="localhost,example.com"})
        end

        it 'still uses curl for token fetching' do
          is_expected.to contain_file("/opt/actions-runner-#{RUNNER_VERSION}/test_runner/configure_install_runner.sh").
            with_content(%r{curl})
        end

        it 'configures archive resource with proxy' do
          is_expected.to contain_archive("test_runner-actions-runner-linux-x64-#{RUNNER_VERSION}.tar.gz").with(
            'proxy_server' => 'http://proxy.local:8080',
            'proxy_type' => 'http'
          )
        end
      end

      describe 'proxy configuration with runner registration token' do
        let(:params) do
          super().merge(
            'repo_token' => 'MANUAL_TOKEN',
            'http_proxy' => 'http://proxy.local:8080',
            'https_proxy' => 'https://proxy.local:8443',
            'no_proxy' => 'localhost,example.com'
          )
        end

        it 'exports http_proxy environment variable' do
          is_expected.to contain_file("/opt/actions-runner-#{RUNNER_VERSION}/test_runner/configure_install_runner.sh").
            with_content(%r{export http_proxy="http://proxy.local:8080"})
        end

        it 'exports https_proxy environment variable' do
          is_expected.to contain_file("/opt/actions-runner-#{RUNNER_VERSION}/test_runner/configure_install_runner.sh").
            with_content(%r{export https_proxy="https://proxy.local:8443"})
        end

        it 'exports no_proxy environment variable' do
          is_expected.to contain_file("/opt/actions-runner-#{RUNNER_VERSION}/test_runner/configure_install_runner.sh").
            with_content(%r{export no_proxy="localhost,example.com"})
        end

        it 'uses direct token without curl' do
          is_expected.to contain_file("/opt/actions-runner-#{RUNNER_VERSION}/test_runner/configure_install_runner.sh").
            with_content(%r{TOKEN=MANUAL_TOKEN}).
            without_content(%r{curl})
        end

        it 'still configures archive resource with proxy' do
          is_expected.to contain_archive("test_runner-actions-runner-linux-x64-#{RUNNER_VERSION}.tar.gz").with(
            'proxy_server' => 'http://proxy.local:8080',
            'proxy_type' => 'http'
          )
        end
      end

      describe 'proxy configuration in systemd service' do
        let(:params) do
          super().merge(
            'http_proxy' => 'http://proxy.local',
            'https_proxy' => 'http://proxy.local',
            'no_proxy' => 'example.com'
          )
        end

        it 'includes http_proxy in service environment' do
          is_expected.to contain_systemd__unit_file('github-actions-runner.test_runner.service').
            with_content(%r{Environment="http_proxy=http://proxy.local"})
        end

        it 'includes https_proxy in service environment' do
          is_expected.to contain_systemd__unit_file('github-actions-runner.test_runner.service').
            with_content(%r{Environment="https_proxy=http://proxy.local"})
        end

        it 'includes no_proxy in service environment' do
          is_expected.to contain_systemd__unit_file('github-actions-runner.test_runner.service').
            with_content(%r{Environment="no_proxy=example.com"})
        end
      end

      describe 'without proxy configuration' do
        it 'does not set proxy_server in archive resource' do
          is_expected.to contain_archive("test_runner-actions-runner-linux-x64-#{RUNNER_VERSION}.tar.gz").with(
            'proxy_server' => nil,
            'proxy_type' => nil
          )
        end

        it 'does not export proxy variables in configure script' do
          is_expected.to contain_file("/opt/actions-runner-#{RUNNER_VERSION}/test_runner/configure_install_runner.sh").
            without_content(%r{export http_proxy}).
            without_content(%r{export https_proxy}).
            without_content(%r{export no_proxy})
        end
      end
    end
  end
end
