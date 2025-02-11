#!/bin/bash
# ssh-setup.sh
# Purpose: Configure SSH access for both root and regular user on a Linux system
# Usage: ./ssh-setup.sh <username> <public_key_file>

# Check if script is run with sudo/root privileges
if [ "$EUID" -ne 0 ]; then 
    echo "Please run this script with sudo or as root"
    exit 1
fi

# Check if required arguments are provided
if [ "$#" -ne 2 ]; then
    echo "Usage: $0 <username> <public_key_file>"
    echo "Example: $0 myuser ~/.ssh/id_rsa.pub"
    exit 1
fi

USERNAME=$1
PUBLIC_KEY_FILE=$2

# Validate username exists
if ! id "$USERNAME" >/dev/null 2>&1; then
    echo "Error: User $USERNAME does not exist"
    exit 1
fi

# Check if public key file exists
if [ ! -f "$PUBLIC_KEY_FILE" ]; then
    echo "Error: Public key file $PUBLIC_KEY_FILE not found"
    exit 1
fi

# Function to setup SSH for a specific user
setup_ssh_for_user() {
    local user=$1
    local home_dir=$2

    echo "Setting up SSH for $user..."
    
    # Create .ssh directory if it doesn't exist
    mkdir -p "$home_dir/.ssh"
    
    # Copy public key to authorized_keys
    cat "$PUBLIC_KEY_FILE" > "$home_dir/.ssh/authorized_keys"
    
    # Set correct permissions
    chmod 700 "$home_dir/.ssh"
    chmod 600 "$home_dir/.ssh/authorized_keys"
    
    # Set correct ownership
    chown -R "$user:$user" "$home_dir/.ssh"
    
    echo "SSH setup completed for $user"
}

# Setup SSH for regular user
USER_HOME="/home/$USERNAME"
setup_ssh_for_user "$USERNAME" "$USER_HOME"

# Ask if root SSH access should be enabled
read -p "Do you want to enable SSH access for root user? (y/N): " enable_root
if [[ $enable_root =~ ^[Yy]$ ]]; then
    setup_ssh_for_user "root" "/root"
    echo "WARNING: Root SSH access has been enabled. This is not recommended for security reasons."
fi

# Print final instructions
echo -e "\nSetup Complete! Please follow these additional security recommendations:"
echo "1. Test the SSH connection before logging out:"
echo "   ssh -i /path/to/private_key $USERNAME@your_server_ip"
echo "2. Edit /etc/ssh/sshd_config and set:"
echo "   PasswordAuthentication no"
echo "   PermitRootLogin prohibit-password    # or 'no' to disable root SSH completely"
echo "3. Restart SSH service:"
echo "   sudo systemctl restart sshd"

echo -e "\nBackup your private key and keep it secure!"
