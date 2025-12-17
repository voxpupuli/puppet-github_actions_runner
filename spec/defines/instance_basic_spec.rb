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

      describe 'basic instance creation' do
        it { is_expected.to compile.with_all_deps }

        it 'creates instance directory with correct permissions' do
          is_expected.to contain_file('/opt/actions-runner-2.319.1/test_runner').with(
            'ensure' => 'directory',
            'owner' => 'root',
            'group' => 'root',
            'mode' => '0750',
          )
        end

        it 'downloads and extracts runner archive' do
          is_expected.to contain_archive('test_runner-actions-runner-linux-x64-2.319.1.tar.gz').with(
            'ensure' => 'present',
            'user' => 'root',
            'group' => 'root',
            'source' => 'https://github.com/actions/runner/releases/download/v2.319.1/actions-runner-linux-x64-2.319.1.tar.gz',
            'extract' => true,
            'extract_path' => '/opt/actions-runner-2.319.1/test_runner',
            'creates' => '/opt/actions-runner-2.319.1/test_runner/bin',
            'cleanup' => true,
          )
        end

        it 'creates configuration script' do
          is_expected.to contain_file('/opt/actions-runner-2.319.1/test_runner/configure_install_runner.sh').with(
            'ensure' => 'present',
            'mode' => '0755',
            'owner' => 'root',
            'group' => 'root',
          )
        end

        it 'creates systemd service unit' do
          is_expected.to contain_systemd__unit_file('github-actions-runner.test_runner.service').with(
            'ensure' => 'present',
            'enable' => true,
            'active' => true,
          )
        end

        it 'creates runner ownership exec' do
          is_expected.to contain_exec('test_runner-ownership').with(
            'user' => 'root',
            'command' => '/bin/chown -R root:root /opt/actions-runner-2.319.1/test_runner',
            'refreshonly' => true,
          )
        end
      end

      describe 'custom user and group' do
        let(:params) do
          super().merge(
            'user' => 'runner_user',
            'group' => 'runner_group',
          )
        end

        it 'creates directory with custom ownership' do
          is_expected.to contain_file('/opt/actions-runner-2.319.1/test_runner').with(
            'owner' => 'runner_user',
            'group' => 'runner_group',
          )
        end

        it 'runs exec as custom user' do
          is_expected.to contain_exec('test_runner-run_configure_install_runner.sh').with(
            'user' => 'runner_user',
          )
        end

        it 'sets custom ownership in chown command' do
          is_expected.to contain_exec('test_runner-ownership').with(
            'command' => '/bin/chown -R runner_user:runner_group /opt/actions-runner-2.319.1/test_runner',
          )
        end
      end

      describe 'ensure absent' do
        let(:params) do
          super().merge('ensure' => 'absent')
        end

        it 'removes instance directory' do
          is_expected.to contain_file('/opt/actions-runner-2.319.1/test_runner').with(
            'ensure' => 'absent',
          )
        end

        it 'removes archive' do
          is_expected.to contain_archive('test_runner-actions-runner-linux-x64-2.319.1.tar.gz').with(
            'ensure' => 'absent',
          )
        end

        it 'removes systemd service' do
          is_expected.to contain_systemd__unit_file('github-actions-runner.test_runner.service').with(
            'ensure' => 'absent',
            'enable' => false,
            'active' => false,
          )
        end

        it 'does not create check-runner-configured exec' do
          is_expected.not_to contain_exec('test_runner-check-runner-configured')
        end
      end
    end
  end
end
