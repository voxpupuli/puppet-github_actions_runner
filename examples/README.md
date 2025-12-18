# Testing github_actions_runner with Vagrant

This directory contains test infrastructure for testing the `github_actions_runner` module locally using Vagrant.

## Prerequisites

### For M2/M3 Mac (Apple Silicon)

**Option 1: VMware Fusion (Recommended)**
```bash
# Install VMware Fusion 13 or later (free for personal use)
brew install --cask vmware-fusion

# Install Vagrant
brew install vagrant

# Install Vagrant VMware Utility (required bridge)
brew install --cask vagrant-vmware-utility

# Install Vagrant VMware plugin
vagrant plugin install vagrant-vmware-desktop

# Note: VMware Fusion 13+ is required for Apple Silicon support
```

**Option 2: Parallels Desktop**
```bash
# Install Parallels Desktop (commercial)
brew install --cask parallels

# Install Vagrant Parallels plugin
vagrant plugin install vagrant-parallels
```

### For Intel Mac / Linux

```bash
# Install VirtualBox
brew install --cask virtualbox

# Vagrant is included with VirtualBox
```

### Install Vagrant

```bash
brew install vagrant
```

## Quick Start (M2 Mac)

**First-time setup:**
```bash
# Install prerequisites
brew install --cask vmware-fusion         # VMware Fusion 13+
brew install vagrant                       # Vagrant
brew install --cask vagrant-vmware-utility # VMware bridge
vagrant plugin install vagrant-vmware-desktop
```

**Then:**

1. **Navigate to examples directory:**
   ```bash
   cd examples
   ```

2. **Start the VM:**
   ```bash
   # For M2 Mac with VMware Fusion:
   vagrant up --provider=vmware_desktop

   # For M2 Mac with Parallels:
   vagrant up --provider=parallels

   # For Intel Mac with VirtualBox:
   vagrant up --provider=virtualbox

   # Auto-detect (will use best available provider):
   vagrant up
   ```

3. **SSH into the VM:**
   ```bash
   vagrant ssh
   ```

4. **Edit the test manifest:**
   ```bash
   sudo -i
   cd /etc/puppetlabs/code/modules/github_actions_runner/examples
   nano apply_test.pp
   ```

   Update the following variables:
   - `$org_name` - Your GitHub organization
   - `$repo_name` - Your GitHub repository
   - `$personal_access_token` - Your GitHub PAT with appropriate permissions

5. **Run a dry-run test (no changes):**
   ```bash
   puppet apply apply_test.pp --noop
   ```

6. **Apply the configuration:**
   ```bash
   puppet apply apply_test.pp
   ```

7. **Verify the runner:**
   ```bash
   # Check service status
   systemctl status github-actions-runner.*.service

   # View logs
   journalctl -u github-actions-runner.basic-runner.service -f

   # Check in GitHub UI
   # Go to: Settings -> Actions -> Runners
   ```

## Test Scenarios

The `apply_test.pp` file includes 8 different test scenarios:

1. **Basic Runner with PAT** - Standard configuration with Personal Access Token
2. **Runner with Registration Token** - Using manual runner registration token
3. **Runner with Custom User** - Dedicated non-root user
4. **Multiple Runners** - Multiple instances on same host
5. **Organization-Level Runner** - Available to all repos in org
6. **Enterprise-Level Runner** - Enterprise-wide runner
7. **Custom PATH and Environment** - Custom environment configuration
8. **Proxy Configuration** - Instance-specific proxy settings

Uncomment the desired scenario in `apply_test.pp` to test.

## Vagrant Commands

```bash
# Start VM
vagrant up

# SSH into VM
vagrant ssh

# Stop VM (keeps disk)
vagrant halt

# Restart VM
vagrant reload

# Reprovision (re-run setup)
vagrant provision

# Destroy VM (removes all data)
vagrant destroy

# Check VM status
vagrant status
```

## Module Development Workflow

The module directory is automatically synced to the VM at:
```
/etc/puppetlabs/code/modules/github_actions_runner
```

Any changes you make to the module on your host machine are immediately available in the VM.

**Workflow:**
1. Edit module files on your Mac
2. SSH into VM: `vagrant ssh`
3. Go to examples dir: `cd /etc/puppetlabs/code/modules/github_actions_runner/examples`
4. Test changes: `sudo puppet apply apply_test.pp --noop`
5. Apply if satisfied with dry-run: `sudo puppet apply apply_test.pp`

## Testing Different Features

### Testing Runner Registration Token

Edit `apply_test.pp` and uncomment Example 2:

```puppet
class { 'github_actions_runner':
  org_name        => $org_name,
  version_in_path => false,
  disable_update  => false,
}

github_actions_runner::instance { 'manual-token-runner':
  org_name   => $org_name,
  repo_name  => $repo_name,
  repo_token => 'AAAAABBBBBCCCCCDDDDD',  # Get from GitHub UI
  labels     => ['self-hosted', 'linux', 'manual-token'],
}
```

Get a runner registration token from:
- Repository: Settings → Actions → Runners → New self-hosted runner
- Copy the token from the configuration command

### Testing Proxy Configuration

Edit `apply_test.pp` and set proxy variables:

```puppet
$http_proxy = 'http://proxy.local:8080'
$https_proxy = 'http://proxy.local:8080'
$no_proxy = 'localhost,127.0.0.1,.local'
```

Then uncomment the proxy lines in the class declaration.

### Testing Custom Users

Uncomment Example 3 in `apply_test.pp`. This will:
- Create a dedicated `gh-runner` user
- Configure the runner to run as that user
- Add the user to the docker group (if docker is installed)

## Troubleshooting

### VM fails to start

**M2 Mac specific:**
- Make sure you have VMware Fusion **13 or later** installed
- Install vagrant-vmware-utility: `brew install --cask vagrant-vmware-utility`
- The box `bento/ubuntu-22.04` is downloaded automatically (first run takes longer, ~5-10 minutes)
- Box automatically detects ARM64 architecture
- If download fails, try: `vagrant box add bento/ubuntu-22.04 --provider vmware_desktop`
- You may need to use `sudo` for some Vagrant commands on M2 Mac

**Common M2 Mac errors:**
```bash
# Error: "VMware Fusion cannot be found"
# Solution: Make sure VMware Fusion 13+ is installed and run:
brew install --cask vagrant-vmware-utility

# Error: "No usable default provider"
# Solution: Explicitly specify provider:
vagrant up --provider=vmware_desktop
```

**VirtualBox on M2 Mac:**
- VirtualBox does NOT support Apple Silicon - use VMware Fusion or Parallels

### Puppet apply fails

```bash
# Check Puppet version
puppet --version

# Check if modules are installed
puppet module list

# Run with debug output
puppet apply apply_test.pp --debug --noop
```

### Runner doesn't appear in GitHub

1. Check if the service is running:
   ```bash
   systemctl status github-actions-runner.*.service
   ```

2. Check the configuration script output:
   ```bash
   journalctl -u github-actions-runner.basic-runner.service --no-pager
   ```

3. Verify the PAT has correct permissions:
   - `repo` (for repository runners)
   - `admin:org` (for organization runners)
   - `admin:enterprise` (for enterprise runners)

4. Check if token was fetched correctly:
   ```bash
   cat /opt/actions-runner/basic-runner/configure_install_runner.sh
   ```

### Synced folder issues

If module changes aren't reflected:

```bash
# Reload Vagrant with provision
vagrant reload --provision

# Or manually remount
vagrant halt
vagrant up
```

## Architecture Notes

The `bento/ubuntu-22.04` box automatically detects your Mac's architecture:
- **ARM64 (M2/M3)**: Downloads ARM64 version
- **x86_64 (Intel)**: Downloads x86_64 version

Both architectures provide Ubuntu 22.04 LTS with identical functionality.

**Important for M2 Mac:** The Vagrantfile configures the `vmxnet3` network adapter which is required for Apple Silicon. Without this, the VM may fail to boot or get stuck at "Waiting for VM to receive an address".

## Cleaning Up

```bash
# Stop and remove VM
vagrant destroy -f

# Remove downloaded box
vagrant box remove bento/ubuntu-22.04
```

## Next Steps

After successful testing:
1. The runner will appear in your GitHub repository/organization
2. You can trigger workflows that use `runs-on: self-hosted`
3. The runner will automatically pick up jobs with matching labels

## Resources

- [Vagrant Documentation](https://www.vagrantup.com/docs)
- [GitHub Actions Self-hosted Runners](https://docs.github.com/en/actions/hosting-your-own-runners)
- [Module README](../README.md)
