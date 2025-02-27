#!/bin/bash
# all-in-one-ssh-setup.sh
# Usage: sudo ./all-in-one-ssh-setup.sh <username>

# Check if script is run with sudo/root privileges
if [ "$EUID" -ne 0 ]; then 
    echo "Please run this script with sudo"
    exit 1
fi

# Check if username is provided
if [ "$#" -ne 1 ]; then
    echo "Usage: $0 <username>"
    echo "Example: $0 myuser"
    exit 1
fi

USERNAME=$1

# Validate username exists
if ! id "$USERNAME" >/dev/null 2>&1; then
    echo "Error: User $USERNAME does not exist"
    exit 1
fi

USER_HOME="/home/$USERNAME"

# Generate SSH key if it doesn't exist
if [ ! -f "$USER_HOME/.ssh/id_rsa" ]; then
    echo "Generating new SSH key pair..."
    su - "$USERNAME" -c "ssh-keygen -t rsa -b 4096 -f $USER_HOME/.ssh/id_rsa -N ''"
fi

# Setup SSH directories and permissions
echo "Setting up SSH directories..."
mkdir -p "$USER_HOME/.ssh"
mkdir -p "/root/.ssh"
chmod 700 "$USER_HOME/.ssh"
chmod 700 "/root/.ssh"
chown "$USERNAME:$USERNAME" "$USER_HOME/.ssh"

# Configure SSH access
echo "Configuring SSH access..."
cat "$USER_HOME/.ssh/id_rsa.pub" >> "/root/.ssh/authorized_keys"
chmod 600 "/root/.ssh/authorized_keys"
chown root:root "/root/.ssh/authorized_keys"

# Test SSH connection
echo "Testing SSH connection..."
su - "$USERNAME" -c "ssh -o StrictHostKeyChecking=no -o PasswordAuthentication=no root@localhost 'echo SSH connection successful'"

echo -e "\nSetup Complete! You can now SSH to root using:"
echo "ssh root@localhost"
echo -e "\nSecurity Recommendations:"
echo "1. Consider using sudo instead of direct root SSH access"
echo "2. Monitor root SSH access in auth.log"
echo "3. Consider disabling password authentication in /etc/ssh/sshd_config"
