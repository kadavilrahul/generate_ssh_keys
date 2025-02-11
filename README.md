# SSH Setup Script

This script automates the process of setting up SSH key-based authentication on a Linux server. It configures SSH access for both regular users and optionally root (not recommended for security reasons).

## Prerequisites

1. A Linux server where you want to set up SSH access
2. SSH key pair already generated on your local machine
   - If you haven't generated a key pair, run: `ssh-keygen -t rsa -b 4096`
3. Sudo/root access on the server

## Usage

1. First, copy your public key to the server:
   ```bash
   scp ~/.ssh/id_rsa.pub user@server:/tmp/
   ```

2. Download the script and make it executable:
   ```bash
   wget https://raw.githubusercontent.com/yourusername/repo/main/ssh-setup.sh
   chmod +x ssh-setup.sh
   ```

3. Run the script:
   ```bash
   sudo ./ssh-setup.sh username /tmp/id_rsa.pub
   ```

## Features

- Sets up SSH key-based authentication for specified user
- Optional root SSH access setup
- Proper permission settings (700 for .ssh directory, 600 for authorized_keys)
- Correct ownership of SSH directories and files
- Interactive prompts for root SSH setup
- Validation of inputs and prerequisites

## Security Recommendations

1. Disable password authentication after confirming SSH key access works
2. Disable root SSH access unless absolutely necessary
3. Use different SSH keys for different users/servers
4. Regularly rotate SSH keys
5. Monitor SSH access logs
6. Consider setting up fail2ban for additional security

## File Permissions

The script automatically sets the following permissions:
- `.ssh` directory: 700 (rwx------)
- `authorized_keys` file: 600 (rw-------)

## Troubleshooting

1. If SSH connection fails:
   - Check permissions on `.ssh` directory and `authorized_keys` file
   - Verify the correct public key was copied
   - Check SSH service status: `systemctl status sshd`
   - Review logs: `tail -f /var/log/auth.log` or `tail -f /var/log/secure`

2. Common issues:
   - SELinux blocking access
   - Firewall rules preventing SSH
   - Incorrect key permissions
   - Wrong user ownership

## Contributing

Feel free to submit issues and pull requests to improve this script.

## License

MIT License (or your chosen license)

## Disclaimer

This script is provided as-is without any warranty. Always test in a safe environment first and ensure you have a way to access your server if something goes wrong.
