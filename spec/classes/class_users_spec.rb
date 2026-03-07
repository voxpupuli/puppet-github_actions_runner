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
              'repo_name' => 'test_repo',
              'labels' => ['test'],
            },
          },
        }
      end

      describe 'user management' do
        context 'with users defined' do
          let(:params) do
            super().merge(
              'users' => {
                'runner1' => {
                  'home' => '/home/runner1',
                  'shell' => '/bin/bash',
                },
                'runner2' => {
                  'home' => '/srv/runner2',
                  'groups' => ['docker'],
                },
              },
            )
          end

          it 'creates users with specified attributes' do
            is_expected.to contain_user('runner1').with(
              'ensure' => 'present',
              'home' => '/home/runner1',
              'shell' => '/bin/bash',
              'system' => true,
              'managehome' => true,
            )

            is_expected.to contain_user('runner2').with(
              'ensure' => 'present',
              'home' => '/srv/runner2',
              'groups' => ['docker'],
              'system' => true,
              'managehome' => true,
            )
          end

          it 'creates primary groups for users' do
            is_expected.to contain_group('runner1').with(
              'ensure' => 'present',
              'system' => true,
            )

            is_expected.to contain_group('runner2').with(
              'ensure' => 'present',
              'system' => true,
            )
          end

          it 'creates users before groups' do
            is_expected.to contain_user('runner1').that_requires('Group[runner1]')
            is_expected.to contain_user('runner2').that_requires('Group[runner2]')
          end
        end

        context 'with no users defined' do
          let(:params) do
            super().merge('users' => {})
          end

          it 'does not create any runner users' do
            catalogue.resources.select { |r| r.type == 'User' }.each do |user|
              expect(user.title).not_to match(%r{runner})
            end
          end
        end

        context 'with user ensure absent' do
          let(:params) do
            super().merge(
              'users' => {
                'old_runner' => {
                  'ensure' => 'absent',
                },
              },
            )
          end

          it 'removes the user' do
            is_expected.to contain_user('old_runner').with(
              'ensure' => 'absent',
            )
          end

          it 'removes the group' do
            is_expected.to contain_group('old_runner').with(
              'ensure' => 'absent',
            )
          end
        end

        context 'with custom user attributes' do
          let(:params) do
            super().merge(
              'users' => {
                'custom_runner' => {
                  'home' => '/custom/home',
                  'shell' => '/bin/zsh',
                  'comment' => 'Custom runner user',
                  'system' => false,
                  'managehome' => false,
                },
              },
            )
          end

          it 'applies custom attributes' do
            is_expected.to contain_user('custom_runner').with(
              'home' => '/custom/home',
              'shell' => '/bin/zsh',
              'comment' => 'Custom runner user',
              'system' => false,
              'managehome' => false,
            )
          end
        end

        context 'when instance uses managed user' do
          let(:params) do
            super().merge(
              'users' => {
                'runner_user' => {
                  'home' => '/home/runner_user',
                },
              },
              'instances' => {
                'test_runner' => {
                  'repo_name' => 'test_repo',
                  'user' => 'runner_user',
                  'labels' => ['test'],
                },
              },
            )
          end

          it 'creates instance that requires the user' do
            is_expected.to contain_github_actions_runner__instance('test_runner')
              .that_requires('User[runner_user]')
          end
        end
      end
    end
  end
end
