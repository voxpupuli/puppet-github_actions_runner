# frozen_string_literal: true

# Shared contexts and constants for github_actions_runner specs

# Default runner version from Hiera
# This should match the version in data/common.yaml
RUNNER_VERSION = '2.319.1'

# Default base directory from Hiera
# This should match the value in data/common.yaml
BASE_DIR = '/opt/actions-runner'

# Helper method to build versioned path
def versioned_path(version = RUNNER_VERSION)
  "#{BASE_DIR}-#{version}"
end

# Helper method to build instance path
def instance_path(instance_name, version = RUNNER_VERSION, versioned: true)
  base = versioned ? versioned_path(version) : BASE_DIR
  "#{base}/#{instance_name}"
end

RSpec.shared_context 'with default runner version' do
  let(:runner_version) { RUNNER_VERSION }
  let(:base_dir) { BASE_DIR }
  let(:versioned_base) { versioned_path }
end
