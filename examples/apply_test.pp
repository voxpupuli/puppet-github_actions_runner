# Test manifest for github_actions_runner module
#
# Configuration is managed via Hiera.
# Edit: /etc/puppetlabs/code/environments/production/data/common.yaml
#
# Usage: puppet apply apply_test.pp [--noop]
#
# To test without making changes: add --noop flag
# To see verbose output: add --debug flag

# ==============================================================================
# Basic Runner Configuration (from Hiera)
# ==============================================================================

include github_actions_runner

# ==============================================================================
# Notes
# ==============================================================================
#
# 1. Edit Hiera configuration:
#    sudo vim /etc/puppetlabs/code/environments/production/data/common.yaml
#
# 2. Uncomment and set your authentication token:
#    - personal_access_token (for PAT authentication), OR
#    - repo_token (for manual runner token)
#
# 3. Test with --noop first:
#    sudo puppet apply --modulepath=/etc/puppetlabs/code/modules --environment production apply_test.pp --noop
#
# 4. Run actual apply:
#    sudo puppet apply --modulepath=/etc/puppetlabs/code/modules --environment production apply_test.pp
#
# 5. Check runner status:
#    systemctl status github-actions-runner.*.service
#
# 6. View runner logs:
#    journalctl -u github-actions-runner.basic-runner.service -f
#
