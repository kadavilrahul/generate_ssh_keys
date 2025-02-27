#!/bin/bash
# ssh-user-to-root.sh
# Purpose: Configure SSH access from the currently logged-in non-root user to root user
# Usage: sudo ./ssh-user-to-root.sh

# Function to display script usage
show_usage() {
    echo "Usage: sudo $0"
    echo "Note: Run this script as root or with sudo"
}

# Check if script is run with sudo/root privileges
if [ "$EUID" -ne 0 ]; then 
    echo "Please run this script with sudo or as root"
    exit 1
fi

# Automatically detect the username of the user who invoked sudo
USERNAME=$(logname 2>/dev/null)

# Validate that a username was detected
if [ -z "$USERNAME" ]; then
    echo "Error: Could not detect the username. Are you logged in as a non-root user?"
    exit 1
fi

# Validate username exists
if ! id "$USERNAME" >/dev/null 2>&1; then
    echo "Error: User $USERNAME does not exist"
    exit 1
fi

USER_HOME="/home/$USERNAME"

# Function to setup SSH directories with correct permissions
setup_ssh_directory() {
    local user=$1
    local home_dir=$2
    
    echo "Setting up .ssh directory for $user..."
    mkdir -p "$home_dir/.ssh"
    chmod 700 "$home_dir/.ssh"
    chown "$user:$user" "$home_dir/.ssh"
}

# Function to clean existing SSH keys
clean_existing_keys() {
    local user_home=$1
    
    echo "Cleaning existing SSH keys..."
    
    # Remove existing SSH keys
    rm -f "$user_home/.ssh/id_rsa" "$user_home/.ssh/id_rsa.pub"
    
    # Clear root's authorized_keys but keep the file
    : > /root/.ssh/authorized_keys
    
    # Set proper permissions
    chmod 600 /root/.ssh/authorized_keys
    chown root:root /root/.ssh/authorized_keys
}

# Function to generate new SSH key pair
generate_ssh_keys() {
    local user_home=$1
    local username=$2
    
    echo "Generating new SSH key pair..."
    
    # Generate key as the specified user
    su - "$username" -c "ssh-keygen -t rsa -b 4096 -f $user_home/.ssh/id_rsa -N ''"
    
    if [ $? -ne 0 ]; then
        echo "Error: Failed to generate SSH keys"
        exit 1
    fi
}

# Function to configure root SSH access
configure_root_access() {
    local user_home=$1
    
    echo "Configuring root SSH access..."
    
    # Setup root's .ssh directory
    mkdir -p /root/.ssh
    chmod 700 /root/.ssh
    
    # Add user's public key to root's authorized_keys
    cat "$user_home/.ssh/id_rsa.pub" | tee -a /root/.ssh/authorized_keys
    chmod 600 /root/.ssh/authorized_keys
}

# Main execution
echo "Starting SSH configuration for user $USERNAME to root access..."

# Setup SSH directories
setup_ssh_directory "$USERNAME" "$USER_HOME"
setup_ssh_directory "root" "/root"

# Clean existing keys if present
clean_existing_keys "$USER_HOME"

# Generate new SSH keys
generate_ssh_keys "$USER_HOME" "$USERNAME"

# Configure root access
configure_root_access "$USER_HOME"

# Final instructions
echo -e "\nSetup Complete! Please follow these steps to test:"
echo "1. Test the SSH connection:"
echo "   su - $USERNAME"
echo "   ssh root@localhost"
echo ""
echo "2. If you need to remove this setup in the future, run:"
echo "   rm -f $USER_HOME/.ssh/id_rsa $USER_HOME/.ssh/id_rsa.pub"
echo "   : > /root/.ssh/authorized_keys"
echo ""
echo "Security Recommendations:"
echo "1. Consider setting a passphrase for the SSH key"
echo "2. Regularly rotate SSH keys"
echo "3. Monitor root SSH access in auth.log"
echo "4. Consider using sudo instead of direct root SSH access"
