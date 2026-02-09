# Changelog

All notable changes to this project will be documented in this file.
Each new release typically also includes the latest modulesync defaults.
These should not affect the functionality of the module.

## [v2.0.0](https://github.com/voxpupuli/puppet-github_actions_runner/tree/v2.0.0) (2026-02-09)

[Full Changelog](https://github.com/voxpupuli/puppet-github_actions_runner/compare/v1.2.0...v2.0.0)

**Breaking changes:**

- Drop puppet, update openvox minimum version to 8.19 [\#38](https://github.com/voxpupuli/puppet-github_actions_runner/pull/38) ([TheMeier](https://github.com/TheMeier))

**Implemented enhancements:**

- Fix REFERENCE.md missing default values and update runner to 2.331.0 [\#45](https://github.com/voxpupuli/puppet-github_actions_runner/pull/45) ([slauger](https://github.com/slauger))

**Fixed bugs:**

- fix: improve runner registration idempotency check [\#46](https://github.com/voxpupuli/puppet-github_actions_runner/pull/46) ([slauger](https://github.com/slauger))

**Merged pull requests:**

- Modernize module: Hiera migration, proxy support, user management, and manual token authentication [\#43](https://github.com/voxpupuli/puppet-github_actions_runner/pull/43) ([slauger](https://github.com/slauger))

## [v1.2.0](https://github.com/voxpupuli/puppet-github_actions_runner/tree/v1.2.0) (2025-04-16)

[Full Changelog](https://github.com/voxpupuli/puppet-github_actions_runner/compare/v1.1.0...v1.2.0)

This release fixes a [security issue](https://github.com/voxpupuli/puppet-github_actions_runner/security/advisories/GHSA-w79w-phhx-9j6m) where anyone with any level of SSH access on the runner host can retrieve the GitHub Personal Access Token (PAT) and other sensitive data from the node runner. The issue was fixed by using more restrictive directory permissions.

**Implemented enhancements:**

- Allow treating personal Github PAT as Sensitive [\#31](https://github.com/voxpupuli/puppet-github_actions_runner/pull/31) ([bfondevila](https://github.com/bfondevila))
- metadata.json: Add OpenVox [\#29](https://github.com/voxpupuli/puppet-github_actions_runner/pull/29) ([jstraw](https://github.com/jstraw))

**Fixed bugs:**

- Adjust tests for new directory permissons [\#33](https://github.com/voxpupuli/puppet-github_actions_runner/pull/33) ([bastelfreak](https://github.com/bastelfreak))

**Merged pull requests:**

- puppet/systemd: allow 8.x [\#26](https://github.com/voxpupuli/puppet-github_actions_runner/pull/26) ([jay7x](https://github.com/jay7x))

## [v1.1.0](https://github.com/voxpupuli/puppet-github_actions_runner/tree/v1.1.0) (2024-08-27)

[Full Changelog](https://github.com/voxpupuli/puppet-github_actions_runner/compare/v1.0.0...v1.1.0)

**Implemented enhancements:**

- Add ARM support [\#22](https://github.com/voxpupuli/puppet-github_actions_runner/pull/22) ([bastelfreak](https://github.com/bastelfreak))

**Merged pull requests:**

- puppetmodule.info: Switch to https links [\#21](https://github.com/voxpupuli/puppet-github_actions_runner/pull/21) ([bastelfreak](https://github.com/bastelfreak))

## [v1.0.0](https://github.com/voxpupuli/puppet-github_actions_runner/tree/v1.0.0) (2024-08-19)

[Full Changelog](https://github.com/voxpupuli/puppet-github_actions_runner/compare/0.10.0...v1.0.0)

**Breaking changes:**

- Drop EoL ubuntu 18.04 [\#19](https://github.com/voxpupuli/puppet-github_actions_runner/pull/19) ([bastelfreak](https://github.com/bastelfreak))
- Drop EoL CentOS 7 support [\#17](https://github.com/voxpupuli/puppet-github_actions_runner/pull/17) ([bastelfreak](https://github.com/bastelfreak))
- Drop EoL Debian 9 & 10 [\#15](https://github.com/voxpupuli/puppet-github_actions_runner/pull/15) ([bastelfreak](https://github.com/bastelfreak))
- Require Puppet 7 or 8 [\#2](https://github.com/voxpupuli/puppet-github_actions_runner/pull/2) ([bastelfreak](https://github.com/bastelfreak))

**Implemented enhancements:**

- Add Ubuntu 24.04 support [\#18](https://github.com/voxpupuli/puppet-github_actions_runner/pull/18) ([bastelfreak](https://github.com/bastelfreak))
- Add CentOS 9 support [\#16](https://github.com/voxpupuli/puppet-github_actions_runner/pull/16) ([bastelfreak](https://github.com/bastelfreak))
- Allow Debian 11 and 12 [\#14](https://github.com/voxpupuli/puppet-github_actions_runner/pull/14) ([bastelfreak](https://github.com/bastelfreak))
- systemd & archive: Allow latest versions [\#13](https://github.com/voxpupuli/puppet-github_actions_runner/pull/13) ([bastelfreak](https://github.com/bastelfreak))
- Add support for repo tokens [\#10](https://github.com/voxpupuli/puppet-github_actions_runner/pull/10) ([bastelfreak](https://github.com/bastelfreak))
- systemd template: Add Puppet header [\#9](https://github.com/voxpupuli/puppet-github_actions_runner/pull/9) ([bastelfreak](https://github.com/bastelfreak))
- Support adding runner to runner groups [\#7](https://github.com/voxpupuli/puppet-github_actions_runner/pull/7) ([bastelfreak](https://github.com/bastelfreak))
- Allow github token to be retrieved from a deferred function [\#6](https://github.com/voxpupuli/puppet-github_actions_runner/pull/6) ([bastelfreak](https://github.com/bastelfreak))
- Update Runner 2.292.0-\>2.319.1 [\#5](https://github.com/voxpupuli/puppet-github_actions_runner/pull/5) ([bastelfreak](https://github.com/bastelfreak))
- Move from Hiera to init.pp [\#4](https://github.com/voxpupuli/puppet-github_actions_runner/pull/4) ([bastelfreak](https://github.com/bastelfreak))
- puppet-lint: validate param documentation [\#3](https://github.com/voxpupuli/puppet-github_actions_runner/pull/3) ([bastelfreak](https://github.com/bastelfreak))

**Fixed bugs:**

- metadata.json: Drop deprecated data\_provider attribute [\#11](https://github.com/voxpupuli/puppet-github_actions_runner/pull/11) ([bastelfreak](https://github.com/bastelfreak))

**Merged pull requests:**

- migrate module to Vox Pupuli [\#12](https://github.com/voxpupuli/puppet-github_actions_runner/pull/12) ([bastelfreak](https://github.com/bastelfreak))
- modulesync 9.1.0 + puppet-lint cleanup [\#1](https://github.com/voxpupuli/puppet-github_actions_runner/pull/1) ([bastelfreak](https://github.com/bastelfreak))

## [0.10.0](https://github.com/voxpupuli/puppet-github_actions_runner/tree/0.10.0) (2022-06-06)

[Full Changelog](https://github.com/voxpupuli/puppet-github_actions_runner/compare/0.9.0...0.10.0)

## [0.9.0](https://github.com/voxpupuli/puppet-github_actions_runner/tree/0.9.0) (2022-05-25)

[Full Changelog](https://github.com/voxpupuli/puppet-github_actions_runner/compare/0.8.0...0.9.0)

## [0.8.0](https://github.com/voxpupuli/puppet-github_actions_runner/tree/0.8.0) (2022-01-18)

[Full Changelog](https://github.com/voxpupuli/puppet-github_actions_runner/compare/0.7.1...0.8.0)

## [0.7.1](https://github.com/voxpupuli/puppet-github_actions_runner/tree/0.7.1) (2022-01-12)

[Full Changelog](https://github.com/voxpupuli/puppet-github_actions_runner/compare/0.7.0...0.7.1)

## [0.7.0](https://github.com/voxpupuli/puppet-github_actions_runner/tree/0.7.0) (2021-11-10)

[Full Changelog](https://github.com/voxpupuli/puppet-github_actions_runner/compare/0.6.0...0.7.0)

## [0.6.0](https://github.com/voxpupuli/puppet-github_actions_runner/tree/0.6.0) (2021-07-29)

[Full Changelog](https://github.com/voxpupuli/puppet-github_actions_runner/compare/0.5.0...0.6.0)

## [0.5.0](https://github.com/voxpupuli/puppet-github_actions_runner/tree/0.5.0) (2021-06-07)

[Full Changelog](https://github.com/voxpupuli/puppet-github_actions_runner/compare/0.4.0...0.5.0)

## [0.4.0](https://github.com/voxpupuli/puppet-github_actions_runner/tree/0.4.0) (2021-02-22)

[Full Changelog](https://github.com/voxpupuli/puppet-github_actions_runner/compare/0.3.0...0.4.0)

## [0.3.0](https://github.com/voxpupuli/puppet-github_actions_runner/tree/0.3.0) (2021-02-11)

[Full Changelog](https://github.com/voxpupuli/puppet-github_actions_runner/compare/0.2.4...0.3.0)

## [0.2.4](https://github.com/voxpupuli/puppet-github_actions_runner/tree/0.2.4) (2021-01-13)

[Full Changelog](https://github.com/voxpupuli/puppet-github_actions_runner/compare/0.2.3...0.2.4)

## [0.2.3](https://github.com/voxpupuli/puppet-github_actions_runner/tree/0.2.3) (2020-10-21)

[Full Changelog](https://github.com/voxpupuli/puppet-github_actions_runner/compare/0.2.2...0.2.3)

## [0.2.2](https://github.com/voxpupuli/puppet-github_actions_runner/tree/0.2.2) (2020-10-20)

[Full Changelog](https://github.com/voxpupuli/puppet-github_actions_runner/compare/0.2.1...0.2.2)

## [0.2.1](https://github.com/voxpupuli/puppet-github_actions_runner/tree/0.2.1) (2020-10-16)

[Full Changelog](https://github.com/voxpupuli/puppet-github_actions_runner/compare/0.2.0...0.2.1)

## [0.2.0](https://github.com/voxpupuli/puppet-github_actions_runner/tree/0.2.0) (2020-10-15)

[Full Changelog](https://github.com/voxpupuli/puppet-github_actions_runner/compare/0.1.2...0.2.0)

## [0.1.2](https://github.com/voxpupuli/puppet-github_actions_runner/tree/0.1.2) (2020-09-21)

[Full Changelog](https://github.com/voxpupuli/puppet-github_actions_runner/compare/0.1.1...0.1.2)

## [0.1.1](https://github.com/voxpupuli/puppet-github_actions_runner/tree/0.1.1) (2020-09-08)

[Full Changelog](https://github.com/voxpupuli/puppet-github_actions_runner/compare/0.1.0...0.1.1)

## [0.1.0](https://github.com/voxpupuli/puppet-github_actions_runner/tree/0.1.0) (2020-09-07)

[Full Changelog](https://github.com/voxpupuli/puppet-github_actions_runner/compare/60635a8c4b2695378b681efe2268440103f74a9a...0.1.0)



\* *This Changelog was automatically generated by [github_changelog_generator](https://github.com/github-changelog-generator/github-changelog-generator)*
