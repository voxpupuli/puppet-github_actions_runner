# frozen_string_literal: true

require 'spec_helper'

describe 'github_actions_runner' do
  on_supported_os.each do |os, os_facts|
    context "on #{os}" do
      let(:facts) { os_facts }
      let(:params) do
        {
          'org_name' => 'github_org',
          'instances' => {
            'first_runner' => {
              'labels' => %w[test_label1 test_label2],
              'repo_name' => 'test_repo',
            },
          },
        }
      end

      context 'basic class compilation' do
        it { is_expected.to compile.with_all_deps }
        it { is_expected.to contain_class('github_actions_runner') }
      end

      context 'validation' do
        context 'when org_name and enterprise_name are both undefined' do
          let(:params) do
            super().merge('org_name' => :undef, 'enterprise_name' => :undef)
          end

          it 'fails with appropriate error message' do
            is_expected.to compile.and_raise_error(%r{Either 'org_name' or 'enterprise_name' is required to create runner instances})
          end
        end
      end

      context 'root directory creation' do
        context 'with default version_in_path (true)' do
          it 'creates versioned root directory' do
            is_expected.to contain_file('/some_dir/actions-runner-2.319.1').with(
              'ensure' => 'directory',
              'owner' => 'root',
              'group' => 'root',
              'mode' => '0750'
            )
          end
        end

        context 'with version_in_path explicitly true' do
          let(:params) do
            super().merge('version_in_path' => true)
          end

          it 'creates versioned root directory' do
            is_expected.to contain_file('/some_dir/actions-runner-2.319.1').with(
              'ensure' => 'directory'
            )
          end
        end

        context 'with version_in_path false' do
          let(:params) do
            super().merge('version_in_path' => false)
          end

          it 'creates non-versioned root directory' do
            is_expected.to contain_file('/some_dir/actions-runner').with(
              'ensure' => 'directory',
              'owner' => 'root',
              'group' => 'root',
              'mode' => '0750'
            )
          end

          it 'does not create versioned directory' do
            is_expected.not_to contain_file('/some_dir/actions-runner-2.319.1')
          end
        end

        context 'with custom base_dir_name' do
          let(:params) do
            super().merge('base_dir_name' => '/opt/actions-runner')
          end

          it 'creates root directory at custom location' do
            is_expected.to contain_file('/opt/actions-runner-2.319.1').with(
              'ensure' => 'directory',
              'owner' => 'root',
              'group' => 'root',
              'mode' => '0750'
            )
          end
        end

        context 'with custom base_dir_name and version_in_path false' do
          let(:params) do
            super().merge(
              'base_dir_name' => '/opt/actions-runner',
              'version_in_path' => false
            )
          end

          it 'creates non-versioned directory at custom location' do
            is_expected.to contain_file('/opt/actions-runner').with(
              'ensure' => 'directory'
            )
          end
        end

        context 'with custom user and group' do
          let(:params) do
            super().merge(
              'user' => 'test_user',
              'group' => 'test_group'
            )
          end

          it 'creates root directory with custom ownership' do
            is_expected.to contain_file('/some_dir/actions-runner-2.319.1').with(
              'ensure' => 'directory',
              'owner' => 'test_user',
              'group' => 'test_group',
              'mode' => '0750'
            )
          end
        end

        context 'with different package version' do
          let(:params) do
            super().merge('package_ensure' => '9.9.9')
          end

          it 'creates root directory with new version' do
            is_expected.to contain_file('/some_dir/actions-runner-9.9.9').with(
              'ensure' => 'directory'
            )
          end
        end
      end

      context 'ensure parameter' do
        context 'when ensure is present' do
          let(:params) do
            super().merge('ensure' => 'present')
          end

          it 'creates directory' do
            is_expected.to contain_file('/some_dir/actions-runner-2.319.1').with(
              'ensure' => 'directory'
            )
          end
        end

        context 'when ensure is absent' do
          let(:params) do
            super().merge('ensure' => 'absent')
          end

          it 'removes directory' do
            is_expected.to contain_file('/some_dir/actions-runner-2.319.1').with(
              'ensure' => 'absent',
              'force' => true
            )
          end
        end
      end

      context 'instance management' do
        context 'with single instance' do
          it 'creates the instance' do
            is_expected.to contain_github_actions_runner__instance('first_runner')
          end
        end

        context 'with multiple instances' do
          let(:params) do
            super().merge(
              'instances' => {
                'runner1' => {
                  'repo_name' => 'repo1',
                  'labels' => ['label1'],
                },
                'runner2' => {
                  'repo_name' => 'repo2',
                  'labels' => ['label2'],
                },
                'runner3' => {
                  'repo_name' => 'repo3',
                  'labels' => ['label3'],
                },
              }
            )
          end

          it 'creates all instances' do
            is_expected.to contain_github_actions_runner__instance('runner1')
            is_expected.to contain_github_actions_runner__instance('runner2')
            is_expected.to contain_github_actions_runner__instance('runner3')
          end
        end

        context 'with no instances' do
          let(:params) do
            super().merge('instances' => {})
          end

          it 'compiles without errors' do
            is_expected.to compile.with_all_deps
          end

          it 'creates root directory' do
            is_expected.to contain_file('/some_dir/actions-runner-2.319.1')
          end
        end
      end

      context 'global parameters inheritance' do
        let(:params) do
          super().merge(
            'org_name' => 'global_org',
            'personal_access_token' => 'global_pat',
            'user' => 'global_user',
            'group' => 'global_group',
            'http_proxy' => 'http://global-proxy.local',
            'https_proxy' => 'https://global-proxy.local',
            'no_proxy' => 'localhost',
            'disable_update' => true,
            'path' => ['/usr/bin', '/bin'],
            'env' => { 'GLOBAL' => 'value' }
          )
        end

        it 'passes parameters to instances' do
          is_expected.to contain_github_actions_runner__instance('first_runner')
        end
      end

      context 'version_in_path interaction with package_ensure' do
        context 'changing package_ensure with version_in_path true' do
          let(:params) do
            super().merge(
              'package_ensure' => '3.0.0',
              'version_in_path' => true
            )
          end

          it 'creates new versioned directory' do
            is_expected.to contain_file('/some_dir/actions-runner-3.0.0').with(
              'ensure' => 'directory'
            )
          end
        end

        context 'changing package_ensure with version_in_path false' do
          let(:params) do
            super().merge(
              'package_ensure' => '3.0.0',
              'version_in_path' => false
            )
          end

          it 'uses same non-versioned directory' do
            is_expected.to contain_file('/some_dir/actions-runner').with(
              'ensure' => 'directory'
            )
          end
        end
      end

      context 'GitHub Enterprise Server configuration' do
        let(:params) do
          super().merge(
            'github_domain' => 'https://git.example.com',
            'github_api' => 'https://git.example.com/api/v3'
          )
        end

        it 'passes custom URLs to instances' do
          is_expected.to contain_github_actions_runner__instance('first_runner')
        end
      end

      context 'enterprise level runners' do
        let(:params) do
          super().merge(
            'org_name' => :undef,
            'enterprise_name' => 'test_enterprise',
            'instances' => {
              'enterprise_runner' => {
                'labels' => ['enterprise'],
              },
            }
          )
        end

        it 'compiles successfully' do
          is_expected.to compile.with_all_deps
        end

        it 'creates enterprise runner instance' do
          is_expected.to contain_github_actions_runner__instance('enterprise_runner')
        end
      end

      context 'user management' do
        context 'with single user' do
          let(:params) do
            super().merge(
              'users' => {
                'github-runner' => {
                  'home' => '/home/github-runner',
                  'shell' => '/bin/bash',
                }
              }
            )
          end

          it 'creates group' do
            is_expected.to contain_group('github-runner').with(
              'ensure' => 'present',
              'system' => true
            )
          end

          it 'creates user with correct attributes' do
            is_expected.to contain_user('github-runner').with(
              'ensure' => 'present',
              'gid' => 'github-runner',
              'home' => '/home/github-runner',
              'shell' => '/bin/bash',
              'managehome' => true,
              'system' => true,
              'comment' => 'GitHub Actions Runner user'
            )
          end

          it 'user requires group' do
            is_expected.to contain_user('github-runner').that_requires('Group[github-runner]')
          end
        end

        context 'with multiple users' do
          let(:params) do
            super().merge(
              'users' => {
                'runner1' => {},
                'runner2' => {
                  'home' => '/srv/runner2',
                },
                'runner3' => {
                  'shell' => '/bin/zsh',
                }
              }
            )
          end

          it 'creates all users' do
            is_expected.to contain_user('runner1')
            is_expected.to contain_user('runner2')
            is_expected.to contain_user('runner3')
          end

          it 'creates all groups' do
            is_expected.to contain_group('runner1')
            is_expected.to contain_group('runner2')
            is_expected.to contain_group('runner3')
          end

          it 'applies custom home directory' do
            is_expected.to contain_user('runner2').with('home' => '/srv/runner2')
          end

          it 'applies custom shell' do
            is_expected.to contain_user('runner3').with('shell' => '/bin/zsh')
          end
        end

        context 'with no users defined' do
          let(:params) do
            super().merge('users' => {})
          end

          it 'does not create any users' do
            catalogue.resources.select { |r| r.type == 'User' }.each do |user|
              expect(user.title).not_to match(%r{runner})
            end
          end
        end

        context 'user with ensure absent' do
          let(:params) do
            super().merge(
              'users' => {
                'old-runner' => {
                  'ensure' => 'absent',
                }
              }
            )
          end

          it 'removes user' do
            is_expected.to contain_user('old-runner').with('ensure' => 'absent')
          end

          it 'removes group' do
            is_expected.to contain_group('old-runner').with('ensure' => 'absent')
          end
        end
      end
    end
  end
end
