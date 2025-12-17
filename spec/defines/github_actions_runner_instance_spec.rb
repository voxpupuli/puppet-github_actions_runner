# frozen_string_literal: true

require 'spec_helper'

describe 'github_actions_runner::instance' do
  let(:title) { 'test_runner' }
  let(:pre_condition) do
    <<-PUPPET
    class { 'github_actions_runner':
      org_name => 'test_org',
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

      context 'basic instance creation' do
        it { is_expected.to compile.with_all_deps }

        it 'creates instance directory' do
          is_expected.to contain_file('/some_dir/actions-runner-2.319.1/test_runner').with(
            'ensure' => 'directory',
            'owner' => 'root',
            'group' => 'root',
            'mode' => '0750'
          )
        end

        it 'downloads and extracts archive' do
          is_expected.to contain_archive('test_runner-actions-runner-linux-x64-2.319.1.tar.gz').with(
            'ensure' => 'present',
            'user' => 'root',
            'group' => 'root'
          )
        end

        it 'creates configure script' do
          is_expected.to contain_file('/some_dir/actions-runner-2.319.1/test_runner/configure_install_runner.sh').with(
            'ensure' => 'present',
            'mode' => '0755',
            'owner' => 'root',
            'group' => 'root'
          )
        end
      end

      context 'configure script content for PAT authentication' do
        it 'contains curl command for token fetching' do
          is_expected.to contain_file('/some_dir/actions-runner-2.319.1/test_runner/configure_install_runner.sh').
            with_content(%r{curl -s -XPOST -H "authorization: token PAT"})
        end

        it 'contains correct token URL for repo' do
          is_expected.to contain_file('/some_dir/actions-runner-2.319.1/test_runner/configure_install_runner.sh').
            with_content(%r{https://api.github.com/repos/test_org/test_repo/actions/runners/registration-token})
        end

        it 'contains correct repository URL' do
          is_expected.to contain_file('/some_dir/actions-runner-2.319.1/test_runner/configure_install_runner.sh').
            with_content(%r{--url https://github.com/test_org/test_repo})
        end

        it 'contains labels' do
          is_expected.to contain_file('/some_dir/actions-runner-2.319.1/test_runner/configure_install_runner.sh').
            with_content(%r{--labels test_label1,test_label2})
        end
      end

      context 'when using repo_token instead of PAT' do
        let(:params) do
          super().merge(
            'repo_token' => 'MANUAL_TOKEN_12345'
          )
        end

        it { is_expected.to compile.with_all_deps }

        it 'uses direct token assignment' do
          is_expected.to contain_file('/some_dir/actions-runner-2.319.1/test_runner/configure_install_runner.sh').
            with_content(%r{TOKEN=MANUAL_TOKEN_12345})
        end

        it 'does not contain curl command' do
          is_expected.to contain_file('/some_dir/actions-runner-2.319.1/test_runner/configure_install_runner.sh').
            without_content(%r{curl})
        end

        it 'does not fetch token from API' do
          is_expected.to contain_file('/some_dir/actions-runner-2.319.1/test_runner/configure_install_runner.sh').
            without_content(%r{registration-token})
        end
      end

      context 'when using repo_token with Sensitive type' do
        let(:params) do
          super().merge(
            'repo_token' => sensitive('SENSITIVE_TOKEN_999')
          )
        end

        it 'handles sensitive repo_token correctly' do
          is_expected.to contain_file('/some_dir/actions-runner-2.319.1/test_runner/configure_install_runner.sh').
            with_content(%r{TOKEN=SENSITIVE_TOKEN_999})
        end
      end

      context 'when repo_token is set without org_name' do
        let(:params) do
          super().merge(
            'org_name' => :undef,
            'repo_token' => 'TOKEN123'
          )
        end

        it 'fails with appropriate error message' do
          is_expected.to compile.and_raise_error(%r{When using 'repo_token', both 'org_name' and 'repo_name' are required})
        end
      end

      context 'when repo_token is set without repo_name' do
        let(:params) do
          super().merge(
            'repo_name' => :undef,
            'repo_token' => 'TOKEN123'
          )
        end

        it 'fails validation for missing repo_name' do
          is_expected.to compile.and_raise_error(%r{parameter 'repo_name'})
        end
      end

      context 'proxy support with PAT authentication' do
        let(:params) do
          super().merge(
            'http_proxy' => 'http://proxy.local:8080',
            'https_proxy' => 'https://proxy.local:8443',
            'no_proxy' => 'localhost,example.com'
          )
        end

        it 'exports http_proxy before curl' do
          is_expected.to contain_file('/some_dir/actions-runner-2.319.1/test_runner/configure_install_runner.sh').
            with_content(%r{export http_proxy="http://proxy.local:8080"})
        end

        it 'exports https_proxy before curl' do
          is_expected.to contain_file('/some_dir/actions-runner-2.319.1/test_runner/configure_install_runner.sh').
            with_content(%r{export https_proxy="https://proxy.local:8443"})
        end

        it 'exports no_proxy before curl' do
          is_expected.to contain_file('/some_dir/actions-runner-2.319.1/test_runner/configure_install_runner.sh').
            with_content(%r{export no_proxy="localhost,example.com"})
        end

        it 'still contains curl command' do
          is_expected.to contain_file('/some_dir/actions-runner-2.319.1/test_runner/configure_install_runner.sh').
            with_content(%r{curl})
        end
      end

      context 'proxy support with repo_token authentication' do
        let(:params) do
          super().merge(
            'repo_token' => 'MANUAL_TOKEN',
            'http_proxy' => 'http://proxy.local:8080'
          )
        end

        it 'does not export proxy variables when using repo_token' do
          is_expected.to contain_file('/some_dir/actions-runner-2.319.1/test_runner/configure_install_runner.sh').
            without_content(%r{export http_proxy})
        end

        it 'uses direct token without curl' do
          is_expected.to contain_file('/some_dir/actions-runner-2.319.1/test_runner/configure_install_runner.sh').
            with_content(%r{TOKEN=MANUAL_TOKEN}).
            without_content(%r{curl})
        end
      end

      context 'organization level runner' do
        let(:params) do
          super().merge(
            'repo_name' => :undef,
            'labels' => ['org-runner']
          )
        end

        it 'uses org token URL' do
          is_expected.to contain_file('/some_dir/actions-runner-2.319.1/test_runner/configure_install_runner.sh').
            with_content(%r{https://api.github.com/orgs/test_org/actions/runners/registration-token})
        end

        it 'uses org URL' do
          is_expected.to contain_file('/some_dir/actions-runner-2.319.1/test_runner/configure_install_runner.sh').
            with_content(%r{--url https://github.com/test_org})
        end
      end

      context 'enterprise level runner' do
        let(:params) do
          super().merge(
            'org_name' => :undef,
            'enterprise_name' => 'test_enterprise',
            'repo_name' => :undef,
            'labels' => ['enterprise-runner']
          )
        end

        it 'uses enterprise token URL' do
          is_expected.to contain_file('/some_dir/actions-runner-2.319.1/test_runner/configure_install_runner.sh').
            with_content(%r{https://api.github.com/enterprises/test_enterprise/actions/runners/registration-token})
        end

        it 'uses enterprise URL' do
          is_expected.to contain_file('/some_dir/actions-runner-2.319.1/test_runner/configure_install_runner.sh').
            with_content(%r{--url https://github.com/enterprises/test_enterprise})
        end
      end

      context 'with disable_update enabled' do
        let(:params) do
          super().merge(
            'disable_update' => true
          )
        end

        it 'includes disableupdate flag' do
          is_expected.to contain_file('/some_dir/actions-runner-2.319.1/test_runner/configure_install_runner.sh').
            with_content(%r{--disableupdate})
        end
      end

      context 'with runner_group specified' do
        let(:params) do
          super().merge(
            'runner_group' => 'MyRunnerGroup'
          )
        end

        it 'includes runnergroup flag' do
          is_expected.to contain_file('/some_dir/actions-runner-2.319.1/test_runner/configure_install_runner.sh').
            with_content(%r{--runnergroup MyRunnerGroup})
        end
      end

      context 'custom user and group' do
        let(:params) do
          super().merge(
            'user' => 'runner_user',
            'group' => 'runner_group'
          )
        end

        it 'creates directory with custom ownership' do
          is_expected.to contain_file('/some_dir/actions-runner-2.319.1/test_runner').with(
            'owner' => 'runner_user',
            'group' => 'runner_group'
          )
        end

        it 'runs exec as custom user' do
          is_expected.to contain_exec('test_runner-run_configure_install_runner.sh').with(
            'user' => 'runner_user'
          )
        end
      end

      describe '.path file management' do
        it 'creates .path file' do
          is_expected.to contain_file('/some_dir/actions-runner-2.319.1/test_runner/.path').with(
            'ensure' => 'present',
            'owner' => 'root',
            'group' => 'root',
            'mode' => '0644'
          )
        end

        context 'with custom path' do
          let(:params) do
            super().merge(
              'path' => ['/custom/bin', '/usr/local/bin']
            )
          end

          it 'sets custom PATH content' do
            is_expected.to contain_file('/some_dir/actions-runner-2.319.1/test_runner/.path').
              with_content("/custom/bin:/usr/local/bin\n")
          end
        end
      end

      describe '.env file management' do
        it 'creates .env file' do
          is_expected.to contain_file('/some_dir/actions-runner-2.319.1/test_runner/.env').with(
            'ensure' => 'present',
            'owner' => 'root',
            'group' => 'root',
            'mode' => '0644'
          )
        end

        context 'with custom environment variables' do
          let(:params) do
            super().merge(
              'env' => {
                'FOO' => 'bar',
                'BAZ' => 'qux'
              }
            )
          end

          it 'sets custom env content' do
            is_expected.to contain_file('/some_dir/actions-runner-2.319.1/test_runner/.env').
              with_content(%r{FOO=bar}).
              with_content(%r{BAZ=qux})
          end
        end
      end

      context 'systemd service' do
        it 'creates systemd unit file' do
          is_expected.to contain_systemd__unit_file('github-actions-runner.test_runner.service').with(
            'ensure' => 'present',
            'enable' => true,
            'active' => true
          )
        end

        context 'with proxy in systemd service' do
          let(:params) do
            super().merge(
              'http_proxy' => 'http://proxy.local',
              'https_proxy' => 'https://proxy.local',
              'no_proxy' => 'example.com'
            )
          end

          it 'includes proxy environment variables in service' do
            is_expected.to contain_systemd__unit_file('github-actions-runner.test_runner.service').
              with_content(%r{Environment="http_proxy=http://proxy.local"}).
              with_content(%r{Environment="https_proxy=http://proxy.local"}).
              with_content(%r{Environment="no_proxy=example.com"})
          end
        end
      end

      context 'when ensure is absent' do
        let(:params) do
          super().merge(
            'ensure' => 'absent'
          )
        end

        it 'removes all resources' do
          is_expected.to contain_file('/some_dir/actions-runner-2.319.1/test_runner').with(
            'ensure' => 'absent'
          )
          is_expected.to contain_archive('test_runner-actions-runner-linux-x64-2.319.1.tar.gz').with(
            'ensure' => 'absent'
          )
          is_expected.to contain_systemd__unit_file('github-actions-runner.test_runner.service').with(
            'ensure' => 'absent',
            'enable' => false,
            'active' => false
          )
        end

        it 'does not create check-runner-configured exec' do
          is_expected.not_to contain_exec('test_runner-check-runner-configured')
        end
      end

      context 'GitHub Enterprise Server' do
        let(:params) do
          super().merge(
            'github_domain' => 'https://git.example.com',
            'github_api' => 'https://git.example.com/api/v3'
          )
        end

        it 'uses custom domain in URL' do
          is_expected.to contain_file('/some_dir/actions-runner-2.319.1/test_runner/configure_install_runner.sh').
            with_content(%r{--url https://git.example.com/test_org/test_repo})
        end

        it 'uses custom API endpoint' do
          is_expected.to contain_file('/some_dir/actions-runner-2.319.1/test_runner/configure_install_runner.sh').
            with_content(%r{https://git.example.com/api/v3/repos/test_org/test_repo})
        end
      end
    end
  end
end
