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
# @param path List of paths to be used as PATH env in the instance runner. If not defined, file ".path" will be kept as created by the runner scripts. Default value: undef
# @param env List of variables to be used as env variables in the instance runner. If not defined, file ".env" will be kept as created by the runner scripts. (Default: Value set by github_actions_runner Class)
#
class github_actions_runner (
  String[1]                      $personal_access_token = 'PAT',
  Enum['present', 'absent']      $ensure = 'present',
  Stdlib::Absolutepath           $base_dir_name = '/some_dir/actions-runner',
  String[1]                      $package_name = 'actions-runner-linux-x64',
  String[1]                      $package_ensure = '2.292.0',
  String[1]                      $repository_url = 'https://github.com/actions/runner/releases/download',
  String[1]                      $user = 'root',
  String[1]                      $group = 'root',
  Hash[String[1], Hash]          $instances = {},
  String[1]                      $github_domain = 'https://github.com',
  String[1]                      $github_api = 'https://api.github.com',
  Optional[String[1]]            $enterprise_name = undef,
  Optional[String[1]]            $org_name = undef,
  Optional[String[1]]            $http_proxy = undef,
  Optional[String[1]]            $https_proxy = undef,
  Optional[String[1]]            $no_proxy = undef,
  Boolean                        $disable_update = false,
  Optional[Array[String]]        $path = undef,
  Optional[Hash[String, String]] $env = undef,
) {
  $root_dir = "${github_actions_runner::base_dir_name}-${github_actions_runner::package_ensure}"

  $ensure_directory = $github_actions_runner::ensure ? {
    'present' => directory,
    'absent'  => absent,
  }

  file { $github_actions_runner::root_dir:
    ensure => $ensure_directory,
    mode   => '0644',
    owner  => $github_actions_runner::user,
    group  => $github_actions_runner::group,
    force  => true,
  }

  create_resources(github_actions_runner::instance, $github_actions_runner::instances)
}
