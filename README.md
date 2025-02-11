# Linux SSH Setup Guide for Beginners

This guide helps you set up SSH (Secure Shell) access on your Linux server. It includes two scripts that automate the setup process, making it easier for beginners to configure SSH securely.

## What is SSH?

SSH (Secure Shell) is a secure way to connect to and manage your Linux server remotely. Instead of sitting physically at your server, you can connect to it from your local computer.

## Which Script Should I Use?

1. `ssh-setup.sh`: Use this if you want to connect from your Windows/Mac/Linux computer to your Linux server
2. `ssh-user-to-root.sh`: Use this if you're already on your Linux server and want to set up SSH access between a regular user and the root user

## Prerequisites

- A Linux server (Ubuntu, Debian, CentOS, etc.)
- Basic knowledge of terminal commands
- Root or sudo access on your server
- SSH client on your local computer
  - Windows: Use PuTTY or Windows Terminal
  - Mac/Linux: Built-in terminal

## Step-by-Step Guide: Connecting from Your Computer to Server

### 1. On Your Local Computer

Generate an SSH key pair:
```bash
# Windows (in PowerShell or Windows Terminal)
ssh-keygen -t rsa -b 4096

# Mac/Linux
ssh-keygen -t rsa -b 4096
```
Just press Enter for all prompts to use default settings.

### 2. Copy the Script to Your Server

```bash
# Download the script
wget https://raw.githubusercontent.com/yourusername/repo/main/ssh-setup.sh

# Make it executable
chmod +x ssh-setup.sh
```

### 3. Copy Your Public Key to Server

```bash
# Windows
scp C:\Users\YourUsername\.ssh\id_rsa.pub username@server-ip:/tmp/

# Mac/Linux
scp ~/.ssh/id_rsa.pub username@server-ip:/tmp/
```

### 4. Run the Setup Script

```bash
sudo ./ssh-setup.sh your-username /tmp/id_rsa.pub
```

### 5. Test Connection

```bash
ssh username@server-ip
```

## Step-by-Step Guide: Setting Up User-to-Root Access

Use this if you want a regular user to be able to SSH into the root account on the same machine.

### 1. Get the Script

```bash
wget https://raw.githubusercontent.com/yourusername/repo/main/ssh-user-to-root.sh
chmod +x ssh-user-to-root.sh
```

### 2. Run the Script

```bash
sudo ./ssh-user-to-root.sh your-username
```

### 3. Test the Setup

```bash
# Switch to your regular user
su - your-username

# Try connecting to root
ssh root@localhost
```

## Common Issues and Solutions

### "Permission denied" Error
- Make sure you're using the correct username
- Check if you copied the correct public key
- Verify file permissions:
  ```bash
  chmod 700 ~/.ssh
  chmod 600 ~/.ssh/authorized_keys
  ```

### "Connection refused" Error
- Check if SSH service is running:
  ```bash
  sudo systemctl status sshd
  ```
- Verify your firewall settings:
  ```bash
  sudo ufw status  # For Ubuntu/Debian
  sudo firewall-cmd --list-all  # For CentOS/RHEL
  ```

### "Host key verification failed" Error
- Remove the old host key:
  ```bash
  ssh-keygen -R server-ip
  ```

## Security Best Practices

1. **Never share your private key** (the file without .pub extension)
2. Use strong passwords for your user account
3. Keep your system updated:
   ```bash
   sudo apt update && sudo apt upgrade  # For Ubuntu/Debian
   sudo dnf update  # For CentOS/RHEL
   ```
4. Consider disabling password authentication:
   - Edit `/etc/ssh/sshd_config`
   - Set `PasswordAuthentication no`
   - Restart SSH: `sudo systemctl restart sshd`

## Backup Your Keys!

Always keep a backup of your SSH keys in a secure location. If you lose your private key, you'll need to repeat the setup process.

## Getting Help

If you encounter issues:
1. Check the error message carefully
2. Look in the SSH log files:
   ```bash
   sudo tail -f /var/log/auth.log  # Ubuntu/Debian
   sudo tail -f /var/log/secure    # CentOS/RHEL
   ```
3. Make sure you have proper permissions
4. Verify the SSH service is running

## Removing SSH Access

### To remove regular SSH access:
```bash
rm -f ~/.ssh/id_rsa ~/.ssh/id_rsa.pub
rm -f ~/.ssh/authorized_keys
```

### To remove root SSH access:
```bash
rm -f /root/.ssh/authorized_keys
```

## Support and Contributing

Feel free to open issues or submit pull requests if you find ways to improve these scripts.

## Disclaimer

While these scripts aim to make SSH setup easier, always understand what commands you're running on your server. Make sure you have alternative ways to access your server before making SSH changes.

## License

MIT License (or your chosen license)
