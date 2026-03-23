# ANSIBLE'S ROLE WITHIN THE INFRASTRUCTURE
- Turn a fresh Ubuntu EC2 into a properly configured machine that's ready to run containers.

---

### ANSIBLE ROLES
- **Docker** - Install Docker CE from the official repo, configure the daemon with log rotation and production-safe security defaults (live restore, no-new-privilege), and add the Ubuntu user to the docker compose group so the Compose commands work without sudo.
- **Hardening** - Locks down SSH (no root login, no password auth, key-only), install fail2ban to block brute attempts, set kernel network parameters via sysctl to prevent common attack vectors, and raises the open file descriptor limit so the JVM doens't hit OS-level connection caps under load
- **CloudWatch** - Installs and AWS CloudWatch agent and configures it to ship Docker Container logs and system logs to CloudWatch log groups, plus basic host metrics(memory, disk)

---

### HOW IT'S TRIGGERED
- A dedicated EC2 control node adds operational overhead. For the time being, GitHub Actions installs Ansible on the runner, writes the SSH deploy key from GitHub Secrets, and runs site.yml against the inventory. Triggered manually via workflow_dispatch when setting up new EC2s, or it fires automatically when changes are pushed to the ansible/ directory. Every playbook is idempotent.

