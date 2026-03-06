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

      describe '.path file management' do
        it 'creates .path file with correct permissions' do
          is_expected.to contain_file("/opt/actions-runner-#{RUNNER_VERSION}/test_runner/.path").with(
            'ensure' => 'present',
            'owner' => 'root',
            'group' => 'root',
            'mode' => '0644',
          )
        end

        context 'with custom path' do
          let(:params) do
            super().merge('path' => ['/custom/bin', '/usr/local/bin'])
          end

          it 'sets custom PATH content' do
            is_expected.to contain_file("/opt/actions-runner-#{RUNNER_VERSION}/test_runner/.path")
              .with_content("/custom/bin:/usr/local/bin\n")
          end
        end

        context 'with default path (undef)' do
          it 'creates empty .path file' do
            is_expected.to contain_file("/opt/actions-runner-#{RUNNER_VERSION}/test_runner/.path")
              .with_content('')
          end
        end
      end

      describe '.env file management' do
        it 'creates .env file with correct permissions' do
          is_expected.to contain_file("/opt/actions-runner-#{RUNNER_VERSION}/test_runner/.env").with(
            'ensure' => 'present',
            'owner' => 'root',
            'group' => 'root',
            'mode' => '0644',
          )
        end

        context 'with custom environment variables' do
          let(:params) do
            super().merge(
              'env' => {
                'FOO' => 'bar',
                'BAZ' => 'qux',
              },
            )
          end

          it 'sets environment variables in .env file' do
            is_expected.to contain_file("/opt/actions-runner-#{RUNNER_VERSION}/test_runner/.env")
              .with_content(%r{FOO=bar})
              .with_content(%r{BAZ=qux})
          end
        end

        context 'with default env (undef)' do
          it 'creates empty .env file' do
            is_expected.to contain_file("/opt/actions-runner-#{RUNNER_VERSION}/test_runner/.env")
              .with_content('')
          end
        end
      end
    end
  end
end
