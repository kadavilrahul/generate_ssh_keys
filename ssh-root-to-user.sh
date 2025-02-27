#!/bin/bash
# ssh-root-to-user.sh
# Purpose: Configure SSH access from the root user to a regular user
# Usage: sudo ./ssh-root-to-user.sh <username>

# Function to display script usage
show_usage() {
    echo "Usage: sudo $0 <username>"
    echo "Example: sudo $0 myuser"
    echo "Note: Run this script as root or with sudo"
}

# Check if script is run with sudo/root privileges
if [ "$EUID" -ne 0 ]; then 
    echo "Please run this script as root or with sudo"
    exit 1
fi

# Check if username is provided
if [ "$#" -ne 1 ]; then
    show_usage
    exit 1
fi

USERNAME=$1

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
    
    echo "Cleaning existing SSH keys for root..."
    
    # Remove existing SSH keys for root
    rm -f /root/.ssh/id_rsa /root/.ssh/id_rsa.pub
    
    # Clear the user's authorized_keys but keep the file
    : > "$user_home/.ssh/authorized_keys"
    
    # Set proper permissions
    chmod 600 "$user_home/.ssh/authorized_keys"
    chown "$USERNAME:$USERNAME" "$user_home/.ssh/authorized_keys"
}

# Function to generate new SSH key pair for root
generate_ssh_keys() {
    echo "Generating new SSH key pair for root..."
    
    # Generate key as root
    ssh-keygen -t rsa -b 4096 -f /root/.ssh/id_rsa -N ''
    
    if [ $? -ne 0 ]; then
        echo "Error: Failed to generate SSH keys"
        exit 1
    fi
}

# Function to configure user SSH access
configure_user_access() {
    local user_home=$1
    
    echo "Configuring SSH access for root to user $USERNAME..."
    
    # Add root's public key to the user's authorized_keys
    cat /root/.ssh/id_rsa.pub | tee -a "$user_home/.ssh/authorized_keys"
    chmod 600 "$user_home/.ssh/authorized_keys"
    chown "$USERNAME:$USERNAME" "$user_home/.ssh/authorized_keys"
}

# Main execution
echo "Starting SSH configuration for root to access user $USERNAME..."

# Setup SSH directories
setup_ssh_directory "$USERNAME" "$USER_HOME"
setup_ssh_directory "root" "/root"

# Clean existing keys if present
clean_existing_keys "$USER_HOME"

# Generate new SSH keys for root
generate_ssh_keys

# Configure user access
configure_user_access "$USER_HOME"

# Final instructions
echo -e "\nSetup Complete! Please follow these steps to test:"
echo "1. Test the SSH connection from root to $USERNAME:"
echo "   ssh $USERNAME@localhost"
echo ""
echo "2. If you need to remove this setup in the future, run:"
echo "   rm -f /root/.ssh/id_rsa /root/.ssh/id_rsa.pub"
echo "   : > $USER_HOME/.ssh/authorized_keys"
echo ""
echo "Security Recommendations:"
echo "1. Regularly rotate SSH keys"
echo "2. Monitor SSH access in auth.log"
