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

      describe 'PAT authentication (default)' do
        it 'contains curl command for token fetching' do
          is_expected.to contain_file("/opt/actions-runner-#{RUNNER_VERSION}/test_runner/configure_install_runner.sh").
            with_content(%r{curl -s -XPOST -H "authorization: token PAT"})
        end

        it 'uses repository registration token API endpoint' do
          is_expected.to contain_file("/opt/actions-runner-#{RUNNER_VERSION}/test_runner/configure_install_runner.sh").
            with_content(%r{https://api.github.com/repos/test_org/test_repo/actions/runners/registration-token})
        end

        it 'configures with repository URL' do
          is_expected.to contain_file("/opt/actions-runner-#{RUNNER_VERSION}/test_runner/configure_install_runner.sh").
            with_content(%r{--url https://github.com/test_org/test_repo})
        end

        it 'includes configured labels' do
          is_expected.to contain_file("/opt/actions-runner-#{RUNNER_VERSION}/test_runner/configure_install_runner.sh").
            with_content(%r{--labels test_label1,test_label2})
        end
      end

      describe 'runner registration token authentication' do
        let(:params) do
          super().merge('repo_token' => 'MANUAL_TOKEN_12345')
        end

        it { is_expected.to compile.with_all_deps }

        it 'uses direct token assignment' do
          is_expected.to contain_file("/opt/actions-runner-#{RUNNER_VERSION}/test_runner/configure_install_runner.sh").
            with_content(%r{TOKEN=MANUAL_TOKEN_12345})
        end

        it 'does not contain curl command' do
          is_expected.to contain_file("/opt/actions-runner-#{RUNNER_VERSION}/test_runner/configure_install_runner.sh").
            without_content(%r{curl})
        end

        it 'does not fetch token from API' do
          is_expected.to contain_file("/opt/actions-runner-#{RUNNER_VERSION}/test_runner/configure_install_runner.sh").
            without_content(%r{registration-token})
        end

        context 'with Sensitive type' do
          let(:params) do
            super().merge('repo_token' => sensitive('SENSITIVE_TOKEN_999'))
          end

          it 'handles sensitive repo_token correctly' do
            is_expected.to contain_file("/opt/actions-runner-#{RUNNER_VERSION}/test_runner/configure_install_runner.sh").
              with_content(%r{TOKEN=SENSITIVE_TOKEN_999})
          end
        end

        context 'without org_name' do
          let(:pre_condition) do
            <<-PUPPET
            class { 'github_actions_runner':
              enterprise_name => 'test_enterprise',
              personal_access_token => 'PAT',
            }
            PUPPET
          end

          let(:params) do
            {
              'repo_name' => 'test_repo',
              'repo_token' => 'TOKEN123',
              'labels' => %w[test_label1 test_label2]
            }
          end

          it 'fails with validation error' do
            is_expected.to compile.and_raise_error(%r{assert_type.*expects a String.*got Undef})
          end
        end

        context 'without repo_name' do
          let(:params) do
            {
              'org_name' => 'test_org',
              'repo_token' => 'TOKEN123',
              'labels' => %w[test_label1 test_label2]
            }
          end

          it 'fails validation for missing repo_name' do
            is_expected.to compile.and_raise_error(%r{assert_type.*expects a String.*got Undef})
          end
        end
      end

      describe 'organization level runner' do
        let(:params) do
          super().merge('repo_name' => :undef)
        end

        it 'uses organization registration token API endpoint' do
          is_expected.to contain_file("/opt/actions-runner-#{RUNNER_VERSION}/test_runner/configure_install_runner.sh").
            with_content(%r{https://api.github.com/orgs/test_org/actions/runners/registration-token})
        end

        it 'configures with organization URL' do
          is_expected.to contain_file("/opt/actions-runner-#{RUNNER_VERSION}/test_runner/configure_install_runner.sh").
            with_content(%r{--url https://github.com/test_org})
        end
      end

      describe 'enterprise level runner' do
        let(:pre_condition) do
          <<-PUPPET
          class { 'github_actions_runner':
            enterprise_name => 'test_enterprise',
            personal_access_token => 'PAT',
          }
          PUPPET
        end

        let(:params) do
          {
            'enterprise_name' => 'test_enterprise',
            'labels' => %w[test_label1 test_label2]
          }
        end

        it 'uses enterprise registration token API endpoint' do
          is_expected.to contain_file("/opt/actions-runner-#{RUNNER_VERSION}/test_runner/configure_install_runner.sh").
            with_content(%r{https://api.github.com/enterprises/test_enterprise/actions/runners/registration-token})
        end

        it 'configures with enterprise URL' do
          is_expected.to contain_file("/opt/actions-runner-#{RUNNER_VERSION}/test_runner/configure_install_runner.sh").
            with_content(%r{--url https://github.com/enterprises/test_enterprise})
        end
      end

      describe 'runner configuration options' do
        context 'with disable_update enabled' do
          let(:params) do
            super().merge('disable_update' => true)
          end

          it 'includes disableupdate flag' do
            is_expected.to contain_file("/opt/actions-runner-#{RUNNER_VERSION}/test_runner/configure_install_runner.sh").
              with_content(%r{--disableupdate})
          end
        end

        context 'with runner_group specified' do
          let(:params) do
            super().merge('runner_group' => 'MyRunnerGroup')
          end

          it 'includes runnergroup flag' do
            is_expected.to contain_file("/opt/actions-runner-#{RUNNER_VERSION}/test_runner/configure_install_runner.sh").
              with_content(%r{--runnergroup MyRunnerGroup})
          end
        end
      end

      describe 'GitHub Enterprise Server' do
        let(:params) do
          super().merge(
            'github_domain' => 'https://git.example.com',
            'github_api' => 'https://git.example.com/api/v3'
          )
        end

        it 'uses custom domain in runner URL' do
          is_expected.to contain_file("/opt/actions-runner-#{RUNNER_VERSION}/test_runner/configure_install_runner.sh").
            with_content(%r{--url https://git.example.com/test_org/test_repo})
        end

        it 'uses custom API endpoint for token' do
          is_expected.to contain_file("/opt/actions-runner-#{RUNNER_VERSION}/test_runner/configure_install_runner.sh").
            with_content(%r{https://git.example.com/api/v3/repos/test_org/test_repo})
        end
      end
    end
  end
end
