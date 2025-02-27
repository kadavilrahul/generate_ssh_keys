#!/bin/bash
# ssh-root-to-root.sh
# Purpose: Configure SSH access from one root server to another root server
# Usage: ./ssh-root-to-root.sh <destination_server_ip>

# Function to display script usage
show_usage() {
    echo "Usage: $0 <destination_server_ip>"
    echo "Example: $0 192.168.1.100"
    echo "Note: Run this script as root or with sudo"
}

# Check if script is run with sudo/root privileges
if [ "$EUID" -ne 0 ]; then 
    echo "Please run this script as root or with sudo"
    exit 1
fi

# Check if destination server IP is provided
if [ "$#" -ne 1 ]; then
    show_usage
    exit 1
fi

DEST_SERVER=$1

# Function to generate SSH key pair for root
generate_ssh_keys() {
    echo "Generating new SSH key pair for root..."
    
    # Generate key if it doesn't already exist
    if [ ! -f /root/.ssh/id_rsa ]; then
        ssh-keygen -t rsa -b 4096 -f /root/.ssh/id_rsa -N ''
        if [ $? -ne 0 ]; then
            echo "Error: Failed to generate SSH keys"
            exit 1
        fi
    else
        echo "SSH key pair already exists. Skipping key generation."
    fi
}

# Function to copy the public key to the destination server
copy_public_key() {
    echo "Copying public key to the destination server ($DEST_SERVER)..."
    
    # Ensure the destination server is reachable
    if ! ping -c 1 -W 2 "$DEST_SERVER" >/dev/null 2>&1; then
        echo "Error: Destination server $DEST_SERVER is not reachable"
        exit 1
    fi

    # Use ssh-copy-id to copy the public key to the destination server
    ssh-copy-id -i /root/.ssh/id_rsa.pub root@"$DEST_SERVER"
    if [ $? -ne 0 ]; then
        echo "Error: Failed to copy the public key to the destination server"
        exit 1
    fi
}

# Main execution
echo "Starting SSH configuration from this root server to root@$DEST_SERVER..."

# Generate SSH keys for root
generate_ssh_keys

# Copy the public key to the destination server
copy_public_key

# Final instructions
echo -e "\nSetup Complete! You can now SSH from this root server to root@$DEST_SERVER without a password."
echo "Test the connection using:"
echo "   ssh root@$DEST_SERVER"
echo ""
echo "Security Recommendations:"
echo "1. Regularly rotate SSH keys"
echo "2. Monitor SSH access in auth.log on the destination server"
echo "3. Consider restricting root SSH access in /etc/ssh/sshd_config"
