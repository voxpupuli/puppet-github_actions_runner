#
# @summary Manages actions_runner service and configuration
#
# @param ensure Determine if to add or remove the resource.
# @param base_dir_name Location of the base directory for actions runner to be installed.
# @param org_name actions runner org name.
# @param enterprise_name enterprise name for global runners
# @param personal_access_token GitHub PAT with admin permission on the repositories or the origanization.
# @param app_id Numeric ID of the GitHub App used to request runner registration tokens.
# @param app_installation_id Numeric ID of the GitHub App installation.
# @param app_private_key GitHub App PEM private key supplied as a Sensitive value.
# @param package_name GitHub Actions runner offical package name.
# @param package_ensure GitHub Actions runner version to be used.
# @param repository_url URL to download GitHub actions runner.
# @param user User to be used in Service and directories.
# @param group Group to be used in Service and directories.
# @param instances Github Runner Instances to be managed.
# @param github_domain Base URL for Github Domain.
# @param github_api Base URL for Github API.
# @param http_proxy Proxy URL for HTTP traffic. More information at https://docs.github.com/en/actions/hosting-your-own-runners/using-a-proxy-server-with-self-hosted-runners.
# @param https_proxy  Proxy URL for HTTPS traffic. More information at https://docs.github.com/en/actions/hosting-your-own-runners/using-a-proxy-server-with-self-hosted-runners
# @param no_proxy Comma separated list of hosts that should not use a proxy. More information at https://docs.github.com/en/actions/hosting-your-own-runners/using-a-proxy-server-with-self-hosted-runners
# @param disable_update toggle for disabling automatic runner updates.
# @param logoutput Enable or disable output logging for the configure_install_runner.sh script. When enabled, stdout/stderr are visible in Puppet logs. Default: true
# @param path List of paths to be used as PATH env in the instance runner. If not defined, file ".path" will be kept as created by the runner scripts. Default value: undef
# @param env List of variables to be used as env variables in the instance runner. If not defined, file ".env" will be kept as created by the runner scripts. (Default: Value set by github_actions_runner Class)
# @param version_in_path Include package version in the root directory path. When false, enables runner self-updates without re-registration. Default: true (for backwards compatibility)
# @param users Hash of users to create for running GitHub Actions runners. Key is username, value is hash of user attributes.
#
class github_actions_runner (
  Enum['present', 'absent']                           $ensure                = 'present',
  Stdlib::Absolutepath                                $base_dir_name         = '/opt/actions-runner',
  String[1]                                           $package_name          = 'actions-runner-linux-x64',
  # renovate: datasource=github-releases depName=actions/runner
  String[1]                                           $package_ensure        = '2.331.0',
  String[1]                                           $repository_url        = 'https://github.com/actions/runner/releases/download',
  String[1]                                           $user                  = 'root',
  String[1]                                           $group                 = 'root',
  Hash[String[1], Hash]                               $instances             = {},
  String[1]                                           $github_domain         = 'https://github.com',
  String[1]                                           $github_api            = 'https://api.github.com',
  Boolean                                             $disable_update        = false,
  Boolean                                             $logoutput             = true,
  Boolean                                             $version_in_path       = true,
  Hash[String[1], Hash]                               $users                 = {},
  Optional[Variant[Sensitive[String[1]], String[1]]] $personal_access_token = undef,
  Optional[Integer[1]]                                $app_id                = undef,
  Optional[Integer[1]]                                $app_installation_id   = undef,
  Optional[Sensitive[String[1]]]                      $app_private_key       = undef,
  Optional[String[1]]                                 $enterprise_name       = undef,
  Optional[String[1]]                                 $org_name              = undef,
  Optional[String[1]]                                 $http_proxy            = undef,
  Optional[String[1]]                                 $https_proxy           = undef,
  Optional[String[1]]                                 $no_proxy              = undef,
  Optional[Array[String]]                             $path                  = undef,
  Optional[Hash[String, String]]                      $env                   = undef,
) {
  $root_dir = $version_in_path ? {
    true  => "${github_actions_runner::base_dir_name}-${github_actions_runner::package_ensure}",
    false => $github_actions_runner::base_dir_name,
  }

  $ensure_directory = $github_actions_runner::ensure ? {
    'present' => directory,
    'absent'  => absent,
  }

  # Create users for runner instances
  $users.each |String $username, Hash $user_config| {
    $user_defaults = {
      ensure     => 'present',
      gid        => $username,
      home       => "/home/${username}",
      managehome => true,
      shell      => '/bin/bash',
      system     => true,
      comment    => 'GitHub Actions Runner user',
    }

    # Create group first
    group { $username:
      ensure => pick($user_config['ensure'], 'present'),
      system => true,
    }

    # Create user with merged config
    user { $username:
      *       => $user_defaults + $user_config,
      require => Group[$username],
    }
  }

  file { $github_actions_runner::root_dir:
    ensure => $ensure_directory,
    mode   => '0750',
    owner  => $github_actions_runner::user,
    group  => $github_actions_runner::group,
    force  => true,
  }

  # Create instances with proper dependencies on managed users
  $github_actions_runner::instances.each |String $instance_name, Hash $instance_config| {
    # Check if this instance uses a managed user
    $instance_user = $instance_config['user'] ? {
      undef   => $github_actions_runner::user,
      default => $instance_config['user'],
    }

    $user_dependency = ($instance_user in $github_actions_runner::users) ? {
      true  => [User[$instance_user]],
      false => [],
    }

    github_actions_runner::instance { $instance_name:
      *       => $instance_config,
      require => $user_dependency,
    }
  }
}
