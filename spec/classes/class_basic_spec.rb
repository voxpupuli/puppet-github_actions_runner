# frozen_string_literal: true

require 'spec_helper'

describe 'github_actions_runner' do
  on_supported_os.each do |os, os_facts|
    context "on #{os}" do
      let(:facts) { os_facts }

      let(:params) do
        {
          'org_name' => 'test_org',
          'instances' => {
            'test_runner' => {
              'labels' => %w[test_label1 test_label2],
              'repo_name' => 'test_repo'
            }
          }
        }
      end

      describe 'basic class compilation' do
        it { is_expected.to compile.with_all_deps }
        it { is_expected.to contain_class('github_actions_runner') }
      end

      describe 'validation' do
        context 'when org_name and enterprise_name are both undefined' do
          let(:params) do
            super().merge('org_name' => :undef, 'enterprise_name' => :undef)
          end

          it 'fails with appropriate error message' do
            is_expected.to compile.and_raise_error(%r{Either 'org_name' or 'enterprise_name' is required})
          end
        end
      end

      describe 'root directory creation' do
        context 'with default version_in_path (true)' do
          it 'creates versioned root directory' do
            is_expected.to contain_file("/opt/actions-runner-#{RUNNER_VERSION}").with(
              'ensure' => 'directory',
              'owner' => 'root',
              'group' => 'root',
              'mode' => '0750'
            )
          end
        end

        context 'with version_in_path false' do
          let(:params) do
            super().merge('version_in_path' => false)
          end

          it 'creates non-versioned root directory' do
            is_expected.to contain_file('/opt/actions-runner').with(
              'ensure' => 'directory',
              'owner' => 'root',
              'group' => 'root',
              'mode' => '0750'
            )
          end

          it 'does not create versioned directory' do
            is_expected.not_to contain_file("/opt/actions-runner-#{RUNNER_VERSION}")
          end
        end

        context 'with custom base_dir_name' do
          let(:params) do
            super().merge('base_dir_name' => '/custom/runner')
          end

          it 'creates directory at custom location' do
            is_expected.to contain_file("/custom/runner-#{RUNNER_VERSION}").with(
              'ensure' => 'directory'
            )
          end
        end
      end

      describe 'package version changes' do
        context 'with different package version' do
          let(:params) do
            super().merge('package_ensure' => '3.0.0')
          end

          it 'creates directory with new version' do
            is_expected.to contain_file('/opt/actions-runner-3.0.0').with(
              'ensure' => 'directory'
            )
          end
        end
      end

      describe 'instance creation' do
        it 'creates instances from hash' do
          is_expected.to contain_github_actions_runner__instance('test_runner')
        end

        context 'with multiple instances' do
          let(:params) do
            super().merge(
              'instances' => {
                'runner1' => {
                  'repo_name' => 'repo1',
                  'labels' => ['label1']
                },
                'runner2' => {
                  'repo_name' => 'repo2',
                  'labels' => ['label2']
                }
              }
            )
          end

          it 'creates all instances' do
            is_expected.to contain_github_actions_runner__instance('runner1')
            is_expected.to contain_github_actions_runner__instance('runner2')
          end
        end

        context 'with empty instances hash' do
          let(:params) do
            super().merge('instances' => {})
          end

          it 'does not create any instances' do
            expect(catalogue.resources.select { |r| r.type == 'Github_actions_runner::Instance' }).to be_empty
          end
        end
      end

      describe 'ensure absent' do
        let(:params) do
          super().merge('ensure' => 'absent')
        end

        it 'removes root directory' do
          is_expected.to contain_file("/opt/actions-runner-#{RUNNER_VERSION}").with(
            'ensure' => 'absent'
          )
        end
      end
    end
  end
end
