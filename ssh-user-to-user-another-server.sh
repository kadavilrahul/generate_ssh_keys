#!/bin/bash
# ssh-user-to-root-another-server.sh
# Purpose: Configure SSH access from local non-root user to remote root user
# Usage: ./ssh-user-to-root-another-server.sh remote_host

# Function to display script usage
show_usage() {
    echo "Usage: $0 remote_host [remote_user]"
    echo "Example: $0 server.example.com [username]"
    echo "If remote_user is not provided, current username will be used"
}

# Check if remote host is provided
if [ $# -lt 1 ]; then
    show_usage
    exit 1
fi

REMOTE_HOST="$1"
REMOTE_USER="${2:-$(whoami)}"

# Get current username
LOCAL_USERNAME="$(whoami)"
USER_HOME="$HOME"

echo "This script will set up SSH key authentication from $LOCAL_USERNAME to root@$REMOTE_HOST"
echo "You will need the password for $REMOTE_USER@$REMOTE_HOST"

# Function to setup SSH directory with correct permissions
setup_ssh_directory() {
    echo "Setting up local .ssh directory..."
    mkdir -p "$USER_HOME/.ssh"
    chmod 700 "$USER_HOME/.ssh"
}

# Function to check for existing SSH keys
check_existing_keys() {
    if [ -f "$USER_HOME/.ssh/id_rsa" ]; then
        read -p "SSH key already exists. Use existing key? (y/n): " use_existing
        if [[ "$use_existing" =~ ^[Yy]$ ]]; then
            return 0
        fi
    fi
    return 1
}

# Function to generate new SSH key pair
generate_ssh_keys() {
    echo "Generating new SSH key pair..."
    ssh-keygen -t rsa -b 4096 -f "$USER_HOME/.ssh/id_rsa"
    
    if [ $? -ne 0 ]; then
        echo "Error: Failed to generate SSH keys"
        exit 1
    fi
}

# Function to copy public key to remote host using sshpass if available
copy_key_to_remote() {
    echo "Copying public key to remote host's root account..."
    
    # Check if ssh-copy-id is available
    if command -v ssh-copy-id &> /dev/null; then
        echo "First, we'll copy your key to your regular user account on the remote server"
        ssh-copy-id "$REMOTE_USER@$REMOTE_HOST"
        
        if [ $? -ne 0 ]; then
            echo "Error: Failed to copy key to remote user account"
            exit 1
        fi
        
        echo "Now, we'll set up root access using your regular account"
        # Use the now-established key-based auth to set up root access
        ssh "$REMOTE_USER@$REMOTE_HOST" "sudo mkdir -p /root/.ssh && sudo chmod 700 /root/.ssh && cat ~/.ssh/authorized_keys | sudo tee -a /root/.ssh/authorized_keys > /dev/null && sudo chmod 600 /root/.ssh/authorized_keys"
        
        if [ $? -ne 0 ]; then
            echo "Error: Failed to set up root access. Check if $REMOTE_USER has sudo privileges."
            exit 1
        fi
    else
        echo "ssh-copy-id not found. Using manual method."
        echo "Please enter password for $REMOTE_USER@$REMOTE_HOST when prompted."
        
        # First copy key to user account
        cat "$USER_HOME/.ssh/id_rsa.pub" | ssh "$REMOTE_USER@$REMOTE_HOST" "mkdir -p ~/.ssh && chmod 700 ~/.ssh && cat >> ~/.ssh/authorized_keys && chmod 600 ~/.ssh/authorized_keys"
        
        if [ $? -ne 0 ]; then
            echo "Error: Failed to copy key to remote user account"
            exit 1
        fi
        
        # Then use that to set up root access
        echo "Now setting up root access. You may be prompted for your sudo password."
        ssh "$REMOTE_USER@$REMOTE_HOST" "sudo mkdir -p /root/.ssh && sudo chmod 700 /root/.ssh && cat ~/.ssh/authorized_keys | sudo tee -a /root/.ssh/authorized_keys > /dev/null && sudo chmod 600 /root/.ssh/authorized_keys"
        
        if [ $? -ne 0 ]; then
            echo "Error: Failed to set up root access. Check if $REMOTE_USER has sudo privileges."
            exit 1
        fi
    fi
}

# Main execution
echo "Starting SSH configuration for user $LOCAL_USERNAME to root@$REMOTE_HOST..."

# Setup SSH directory
setup_ssh_directory

# Check for existing keys
if ! check_existing_keys; then
    generate_ssh_keys
fi

# Copy key to remote host
copy_key_to_remote

# Final instructions
echo -e "\nSetup Complete! Please follow these steps to test:"
echo "1. Test the SSH connection:"
echo "   ssh root@$REMOTE_HOST"
echo ""
echo "Security Recommendations:"
echo "1. Consider using a non-root user with sudo privileges instead"
echo "2. Configure SSH to disable password authentication after confirming key auth works"
echo "3. Use SSH config file for easier connections"
echo "4. Consider using ssh-agent for key management"
