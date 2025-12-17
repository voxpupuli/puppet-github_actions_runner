#
# @summary Manages actions_runner service and configuration
#
# @param ensure Determine if to add or remove the resource.
# @param base_dir_name Location of the base directory for actions runner to be installed.
# @param org_name actions runner org name.
# @param enterprise_name enterprise name for global runners
# @param personal_access_token GitHub PAT with admin permission on the repositories or the origanization.
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
  Enum['present', 'absent']      $ensure,
  Stdlib::Absolutepath           $base_dir_name,
  String[1]                      $package_name,
  String[1]                      $package_ensure,
  String[1]                      $repository_url,
  String[1]                      $user,
  String[1]                      $group,
  Hash[String[1], Hash]          $instances,
  String[1]                      $github_domain,
  String[1]                      $github_api,
  Boolean                        $disable_update,
  Boolean                        $logoutput,
  Boolean                        $version_in_path,
  Hash[String[1], Hash]          $users,
  $personal_access_token,
  Optional[String[1]]            $enterprise_name,
  Optional[String[1]]            $org_name,
  Optional[String[1]]            $http_proxy,
  Optional[String[1]]            $https_proxy,
  Optional[String[1]]            $no_proxy,
  Optional[Array[String]]        $path,
  Optional[Hash[String, String]] $env,
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

  create_resources(github_actions_runner::instance, $github_actions_runner::instances)
}
