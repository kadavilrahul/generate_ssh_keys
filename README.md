Here's the corrected README with the proper repository URL:

# Linux SSH Setup Guide for Beginners

This guide helps you set up SSH (Secure Shell) access on your Linux server. It includes two scripts that automate the setup process, making it easier for beginners to configure SSH securely.
What is SSH?
SSH (Secure Shell) is a secure way to connect to and manage your Linux server remotely. Instead of sitting physically at your server, you can connect to it from your local computer.

#### Prerequisites
- A Linux server (Ubuntu, Debian, CentOS, etc.)
- Basic knowledge of terminal commands
- Root or sudo access on your server
- SSH client on your local computer
- Windows: Use PuTTY or Windows Terminal
- Mac/Linux: Built-in terminal

## Clone the repository

```bash
git clone https://github.com/kadavilrahul/generate_ssh_keys.git
```

## Use this if you want a regular user to be able to SSH into the root account on the same machine.

### 1. Login to the user you want to connect from

### 2. Run the Script

```bash
sudo bash ssh-user-to-root.sh
```

### 3. Test the Setup

```bash
# Switch to your regular user
su - your-username

# Try connecting to root
ssh root@localhost
```

## Use this if you want a root user to be able to SSH into the regular user on the same machine.

### 1. Login to the root user you want to connect from

### 2. Run the Script
```bash
sudo bash ssh-root-to-user.sh your_username
```

### 2. Test the Setup

```bash
# Switch to your root user
su - root

# Try connecting to root
ssh your_username@localhost
```



---------------------------------------------------------------------------------------------------------
# THIS SECTION IS TO BE UPDATED
















#### Connecting from Your local Computer to Server
1. On Your Local Computer
- Generate an SSH key pair:

Windows (in PowerShell or Windows Terminal)
```
ssh-keygen -t rsa -b 4096
```
Mac/Linux
```
ssh-keygen -t rsa -b 4096
```
Just press Enter for all prompts to use default settings.


3. Copy Your Public Key to Server
Windows
```
scp C:\Users\YourUsername\.ssh\id_rsa.pub username@server-ip:/tmp/
```
Mac/Linux
```
scp ~/.ssh/id_rsa.pub username@server-ip:/tmp/
```
4. Run the Setup Script
```
sudo ./ssh-setup.sh your-username /tmp/id_rsa.pub
```
6. Test Connection

```
ssh username@server-ip
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
" The repo URl is https://github.com/kadavilrahul/generate_ssh_keys
