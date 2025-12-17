# GitHub Actions Runner Puppet Module - Development Notes

## Project Overview

Fork of `voxpupuli/puppet-github_actions_runner` with enhancements for:
- Manual runner token support (without requiring PAT)
- Proxy support for API calls and downloads
- Runner self-updates without re-registration
- User management for non-root runners
- Full Hiera-based configuration

**Repository:** https://github.com/slauger/puppet-github_actions_runner
**Branch:** `feature/manual-runner-token-support`

## Key Features Implemented

### 1. Manual Runner Token Support (`repo_token`)

Instead of requiring a Personal Access Token (PAT) with broad permissions, users can now provide runner registration tokens from repository settings.

**Configuration:**
```yaml
github_actions_runner::instances:
  example_repo_instance:
    repo_name: 'myrepo'
    repo_token: 'AAAAABBBBBCCCCCDDDDD'  # Runner registration token
    labels:
      - self-hosted-custom
```

**Important Notes:**
- When using `repo_token`, both `org_name` and `repo_name` must be specified
- Registration tokens are short-lived (typically 1 hour) and single-use
- Only works for repository-level runners
- No `personal_access_token` required when using `repo_token`

**Implementation Details:**
- `manifests/instance.pp`: Logic checks for `repo_token` and skips PAT-based API authentication
- `templates/configure_install_runner.sh.epp`: Conditionally uses direct token or fetches via API

### 2. Runner Self-Updates (`version_in_path`)

New parameter `version_in_path` (default: `true` for backwards compatibility) controls installation path structure.

**When `version_in_path: false`:**
- Installation path: `/opt/actions-runner/` (no version suffix)
- Runners can self-update without Puppet re-registration
- `_work/` directory preserved across updates
- Recommended when using manually generated tokens

**When `version_in_path: true`:**
- Installation path: `/opt/actions-runner-2.319.1/` (includes version)
- Changing `package_ensure` creates new directory
- Requires re-registration of all runners

**Configuration:**
```yaml
github_actions_runner::version_in_path: false
github_actions_runner::disable_update: false  # Allow self-updates
```

### 3. Proxy Support

Full proxy support for both API calls (PAT-based authentication) and package downloads.

**Configuration:**
```yaml
github_actions_runner::http_proxy: http://proxy.local
github_actions_runner::https_proxy: http://proxy.local
github_actions_runner::no_proxy: localhost,example.com

# Instance-level override
github_actions_runner::instances:
  example_org_instance:
    http_proxy: http://instance_specific_proxy.local
    https_proxy: http://instance_specific_proxy.local
    no_proxy: example.com
```

**Implementation:**
- `templates/configure_install_runner.sh.epp`: Exports proxy env vars before curl API calls
- `manifests/instance.pp`: Configures `archive` resource with `proxy_server` and `proxy_type`
- `templates/github-actions-runner.service.epp`: Sets proxy environment variables in systemd unit

### 4. User Management

Create dedicated non-root users for running runners securely.

**Configuration:**
```yaml
github_actions_runner::users:
  github-runner:
    home: /home/github-runner
    shell: /bin/bash
  prod-runner:
    home: /srv/prod-runner
    groups:
      - docker

github_actions_runner::instances:
  standard_runner:
    repo_name: 'public-repo'
    user: github-runner
    repo_token: 'TOKEN1'

  production_runner:
    repo_name: 'production'
    user: prod-runner
    repo_token: 'TOKEN2'
```

**Implementation:**
- `manifests/init.pp`: Creates users and groups from `$users` hash (lines 60-82)
- User configuration uses hash merge: `$user_defaults + $user_config` (line 79)
- Any parameter in `$user_config` overrides the defaults (e.g., `home`, `shell`, `groups`, etc.)
- `manifests/instance.pp`: Checks if user is managed and adds proper dependencies
- Uses `$user in $github_actions_runner::users` (modern Puppet, not deprecated `has_key()`)

**Available User Parameters:**
All standard Puppet `user` resource parameters can be overridden in the user configuration:
- `home`: Home directory (default: `/home/${username}`)
- `shell`: Login shell (default: `/bin/bash`)
- `groups`: Additional groups (default: none)
- `ensure`: present/absent (default: `present`)
- `managehome`: Create home directory (default: `true`)
- `system`: System user (default: `true`)
- `comment`: User description (default: 'GitHub Actions Runner user')
- And any other valid `user` resource parameter

### 5. Hiera-Based Configuration

All defaults moved to Hiera data layer with architecture-specific hierarchy.

**Structure:**
```
data/
├── common.yaml              # Default values
└── os/
    ├── x86_64.yaml         # Intel/AMD 64-bit
    ├── amd64.yaml          # Intel/AMD 64-bit (alternative name)
    └── aarch64.yaml        # ARM 64-bit
```

**Hierarchy (`hiera.yaml`):**
```yaml
hierarchy:
  - name: "Per architecture"
    path: "os/%{facts.os.architecture}.yaml"
  - name: "Common defaults"
    path: "common.yaml"
```

**Architecture-specific package names:**
- x86_64/amd64: `actions-runner-linux-x64`
- aarch64: `actions-runner-linux-arm64`

## Technical Decisions

### Type Declarations

**Token Parameters:**
- NO type declaration (untyped) for `personal_access_token` and `repo_token`
- Reason: Variant/Optional/Sensitive/Undef combinations caused conflicts with Hiera
- Both in manifests and EPP templates

**Other Optional Parameters:**
- Use `Optional[Type]` pattern (Vox Pupuli standard)
- Example: `Optional[String[1]]`, `Optional[Array[String]]`

### Modern Puppet Syntax

- Use `$key in $hash` instead of deprecated `has_key()`
- Use EPP templates (`.epp`) not ERB (`.erb`)
- Use Hiera 5 with data-in-modules pattern
- Use `stdlib::deferrable_epp()` for deferred evaluation

### Parameter Naming Conventions

**`disable_update` (Singular):**
- Follows GitHub Actions runner CLI convention: `--disableupdate`
- Treats "update" as a feature/capability rather than individual events
- Consistent with upstream GitHub Actions naming
- Maintains backwards compatibility (no breaking changes)
- Alternative `disable_updates` (plural) considered but rejected to match GitHub's official naming

### Directory Structure

```
/opt/actions-runner/                  # Root (when version_in_path: false)
├── instance_name_1/                  # Instance directory
│   ├── bin/                          # Runner binaries
│   ├── _work/                        # Checkout cache (preserved)
│   ├── .path                         # PATH configuration
│   ├── .env                          # Environment variables
│   └── configure_install_runner.sh   # Setup script
└── instance_name_2/
    └── ...
```

## File Reference

### Manifests

**`manifests/init.pp`**
- Main class
- Creates root directory (`$root_dir`)
- Manages users from `$users` hash
- No parameter defaults (all from Hiera)

**`manifests/instance.pp`**
- Define for runner instances
- Handles token logic (`repo_token` vs `personal_access_token`)
- Creates instance directory
- Downloads and extracts archive with proxy support
- Generates configuration script
- Manages `.path` and `.env` files
- Creates systemd service

### Templates

**`templates/configure_install_runner.sh.epp`**
- Bash script to configure runner
- Handles both `repo_token` (direct) and PAT (API fetch) modes
- Exports proxy variables for curl when using PAT
- Runs `config.sh` with appropriate parameters

**`templates/github-actions-runner.service.epp`**
- Systemd unit file
- Runs as specified `$user` (via `User=` directive)
- Sets proxy environment variables
- Executes `runsvc.sh`

**`templates/path.epp`**
- Generates `.path` file for custom PATH

**`templates/env.epp`**
- Generates `.env` file for environment variables

### Data Files

**`data/common.yaml`**
- Default configuration values
- All required parameters
- Optional parameters set to `~` (undef)

**`data/os/{x86_64,amd64,aarch64}.yaml`**
- Architecture-specific `package_name` overrides

**`hiera.yaml`**
- Hiera 5 configuration
- Architecture-based hierarchy

### Tests

**`spec/classes/github_actions_runner_spec.rb`**
- Tests for main class
- Root directory creation
- User management
- Parameter inheritance

**`spec/defines/github_actions_runner_instance_spec.rb`**
- Tests for instance define
- Token authentication modes
- Proxy configuration
- Template content validation

## Common Patterns

### Instance with Manual Token (Recommended)
```yaml
github_actions_runner::org_name: 'my-org'
github_actions_runner::version_in_path: false
github_actions_runner::disable_update: false

github_actions_runner::users:
  runner-user:
    home: /home/runner-user

github_actions_runner::instances:
  my_runner:
    repo_name: 'my-repo'
    repo_token: 'MANUAL_TOKEN_FROM_GITHUB_UI'
    user: runner-user
    labels:
      - custom-label
```

### Instance with PAT (Legacy)
```yaml
github_actions_runner::org_name: 'my-org'
github_actions_runner::personal_access_token: 'ghp_xxxxxxxxxxxx'

github_actions_runner::instances:
  org_runner:
    labels:
      - org-level
```

### With Proxy
```yaml
github_actions_runner::http_proxy: http://proxy.local:8080
github_actions_runner::https_proxy: http://proxy.local:8080
github_actions_runner::no_proxy: localhost,127.0.0.1,.local

github_actions_runner::instances:
  proxied_runner:
    repo_name: 'my-repo'
    repo_token: 'TOKEN'
```

## FAQ / Common Questions

### Can I override the `home` directory for users?

**Yes!** The user management system supports overriding any standard Puppet `user` resource parameter. The implementation in `manifests/init.pp:79` uses hash merging (`$user_defaults + $user_config`), which means any parameter you provide in your configuration will override the defaults.

Example:
```yaml
github_actions_runner::users:
  custom-runner:
    home: /srv/custom-runner      # Overrides default /home/custom-runner
    shell: /bin/zsh               # Overrides default /bin/bash
    groups:                       # Adds additional groups
      - docker
      - sudo
```

The merge operation ensures your configuration takes precedence over defaults.

### Why is it `disable_update` (singular) and not `disable_updates` (plural)?

The parameter name `disable_update` follows GitHub Actions runner's official CLI convention `--disableupdate`. This naming treats "update" as a feature/capability rather than individual update events. While `disable_updates` might be grammatically preferable, we maintain consistency with GitHub's upstream naming to avoid confusion and maintain a clear relationship with the underlying GitHub Actions runner configuration.

## Known Issues / Limitations

1. **puppetlabs-archive proxy support:**
   - Only supports single `proxy_server` parameter
   - No separate `https_proxy` or `no_proxy` support in archive downloads
   - Uses `http_proxy` value for `proxy_server`

2. **Registration token lifetime:**
   - Manually generated tokens expire in ~1 hour
   - Must be used before expiration
   - Recommend using `version_in_path: false` to avoid re-registration

3. **Type system complexity:**
   - Removed type declarations for token parameters to avoid Hiera conflicts
   - Trade-off: Less type safety for better usability

## Development Commands

```bash
# Run tests (requires bundle install)
bundle exec rake spec

# Lint check
bundle exec rake lint

# Validation
bundle exec rake validate

# All checks
bundle exec rake test
```

## Git Workflow

Branch: `feature/manual-runner-token-support`

```bash
# Status
git status

# Commit
git add <files>
git commit -m "message"

# Push
git push origin feature/manual-runner-token-support
```

## Future Considerations

1. Consider upstreaming to voxpupuli/puppet-github_actions_runner
2. Add support for GitHub Enterprise Cloud runners
3. Improve archive proxy support (contribute to puppetlabs-archive?)
4. Add automatic token refresh mechanism
5. Add runner health checks

## References

- Original module: https://github.com/voxpupuli/puppet-github_actions_runner
- GitHub Actions runner docs: https://docs.github.com/en/actions/hosting-your-own-runners
- Puppet type system: https://puppet.com/docs/puppet/latest/lang_data_type.html
- Vox Pupuli best practices: https://voxpupuli.org/docs/
