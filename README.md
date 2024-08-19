# GitHub Actions Runner

[![Build Status](https://github.com/voxpupuli/puppet-github_actions_runner/workflows/CI/badge.svg)](https://github.com/voxpupuli/puppet-github_actions_runner/actions?query=workflow%3ACI)
[![Release](https://github.com/voxpupuli/puppet-github_actions_runner/actions/workflows/release.yml/badge.svg)](https://github.com/voxpupuli/puppet-github_actions_runner/actions/workflows/release.yml)
[![Puppet Forge](https://img.shields.io/puppetforge/v/puppet/github_actions_runner.svg)](https://forge.puppetlabs.com/puppet/github_actions_runner)
[![Puppet Forge - downloads](https://img.shields.io/puppetforge/dt/puppet/github_actions_runner.svg)](https://forge.puppetlabs.com/puppet/github_actions_runner)
[![Puppet Forge - endorsement](https://img.shields.io/puppetforge/e/puppet/github_actions_runner.svg)](https://forge.puppetlabs.com/puppet/github_actions_runner)
[![Puppet Forge - scores](https://img.shields.io/puppetforge/f/puppet/github_actions_runner.svg)](https://forge.puppetlabs.com/puppet/github_actions_runner)
[![puppetmodule.info docs](http://www.puppetmodule.info/images/badge.png)](http://www.puppetmodule.info/m/puppet-github_actions_runner)
[![Apache-2.0 License](https://img.shields.io/github/license/voxpupuli/puppet-github_actions_runner.svg)](LICENSE)
[![Migrated from Telefonica](https://img.shields.io/badge/Migrated%20from-Telefonica-fb7047.svg)](#transfer-notice)

Automatic configuration for running GitHub Actions as a service

#### Table of Contents

* [Description](#description)
* [Hiera configuration examples](#hiera-configuration-examples)
  * [Creating an organization level Actions runner](#creating-an-organization-level-actions-runner)
  * [Creating an additional repository level Actions runner](#creating-an-additional-repository-level-actions-runner)
  * [Instance level overwrites](#instance-level-overwrites)
  * [Adding a global proxy and overwriting an instance level proxy](#adding-a-global-proxy-and-overwriting-an-instance-level-proxy)
* [Github Enterprise examples](#github-enterprise-examples)
* [Update PATH used by Github Runners](#Update-path-used-by-github-runners)
* [Adding environment variables to runner](#adding-environment-variables-to-runner)
* [Limitations - OS compatibility, etc.](#limitations)
* [Development - Guide for contributing to the module](#development)
* [Transfer Notice](#transfer-notice)

## Description

This module will setup all of the files and configuration needed for GitHub Actions runner to work on Debian (Stretch and Buster) and CentOS7 hosts.

### hiera configuration examples

This module supports configuration through hiera.

#### Creating an organization level Actions runner

```yaml
github_actions_runner::ensure: present
github_actions_runner::base_dir_name: '/data/actions-runner'
github_actions_runner::package_name: 'actions-runner-linux-x64'
github_actions_runner::package_ensure: '2.277.1'
github_actions_runner::repository_url: 'https://github.com/actions/runner/releases/download'
github_actions_runner::org_name: 'my_github_organization'
github_actions_runner::personal_access_token: 'PAT'
github_actions_runner::user: 'root'
github_actions_runner::group: 'root'
github_actions_runner::instances:
  example_org_instance:
    labels:
      - self-hosted-custom
    runner_group: 'MyRunners'
```

Note, your `personal_access_token` has to contain the `admin:org` permission.

#### Creating an additional repository level Actions runner
```yaml
github_actions_runner::instances:
  example_org_instance:
    labels:
      - self-hosted-custom1
  example_repo_instance:
    repo_name: myrepo
    labels:
      - self-hosted-custom2
```

Note, your `personal_access_token` has to contain the `repo` permission.

#### Instance level overwrites
```yaml
github_actions_runner::instances:
  example_org_instance:
    ensure: absent
    labels:
      - self-hosted-custom1
  example_repo_instance:
    org_name: overwritten_orgnization
    repo_name: myrepo
    labels:
      - self-hosted-custom2
```

#### Adding a global proxy and overwriting an instance level proxy
```yaml
github_actions_runner::http_proxy: http://proxy.local
github_actions_runner::https_proxy: http://proxy.local
github_actions_runner::instances:
  example_org_instance:
    http_proxy: http://instance_specific_proxy.local
    https_proxy: http://instance_specific_proxy.local
    no_proxy: example.com
    labels:
      - self-hosted-custom1
```

### Github Enterprise examples
To use the module with Github Enterprise Server, you have to define these parameters:
```yaml
github_actions_runner::github_domain: "https://git.example.com"
github_actions_runner::github_api: "https://git.example.com/api/v3"
```

In addition to the runner configuration examples above, you can also configure runners
on the enterprise level by setting a value for `enterprise_name`, for example:
```yaml
github_actions_runner::ensure: present
github_actions_runner::base_dir_name: '/data/actions-runner'
github_actions_runner::package_name: 'actions-runner-linux-x64'
github_actions_runner::package_ensure: '2.277.1'
github_actions_runner::repository_url: 'https://github.com/actions/runner/releases/download'
github_actions_runner::enterprise_name: 'enterprise_name'
github_actions_runner::personal_access_token: 'PAT'
github_actions_runner::user: 'root'
github_actions_runner::group: 'root'
github_actions_runner::instances:
```

Note, your `personal_access_token` has to contain the `admin:enterprise` permission.

## Update PATH used by Github Runners

By default, puppet will not modify the values that the runner scripts create when
the runner is set.

In case you need to use another value of paths in the environment variable PATH,
you can define through hiera. For example:

- For all runners defined:
  ```yaml
  github_actions_runner::path:
    - /usr/local/bin
    - /usr/bin
    - /bin
    - /my/own/path
  ```
- For just a specific runner:
  ```yaml
  github_actions_runner::instances:
    example_org_instance:
      path:
        - /usr/local/bin
        - /usr/bin
        - /bin
        - /my/own/path
      labels:
        - self-hosted-custom
  ```

## Adding environment variables to runner

The runner uses environment variables to decide pre/post-run scripts:
https://docs.github.com/en/actions/hosting-your-own-runners/running-scripts-before-or-after-a-job#triggering-the-scripts

```yaml
github_actions_runner::env:
  ACTIONS_RUNNER_HOOK_JOB_STARTED: "/cleanup_script"
  FOO: "bar"
```


## Limitations

Tested on Debian 9 (stretch), Debian 10 (buster) and CentOS7 hosts.
Full list of operating systems support and requirements are described in `metadata.json` file.

## Development

There are a few guidelines that we need contributors to follow so that we can have a chance of keeping on top of things. For more information, see Puppet Forge [module contribution guide](https://puppet.com/docs/puppet/7.1/modules_publishing.html).

## License

*GitHub Actions Runner* is available under the Apache License, Version 2.0. See LICENSE file
for more info.

## Transfer Notice

This module was originally written by Telefonica:

> https://github.com/Telefonica/puppet-github-actions-runner

They archived the repository and Vox Pupuli forked it in August 2024.
