#!/bin/bash
# root-ssh-setup.sh
# Purpose: Set up SSH key-based authentication from local non-root user to remote root user
# Usage: ./root-ssh-setup.sh remote_host [remote_user]

# Color codes for better readability
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Function to display script usage
show_usage() {
    echo -e "${BLUE}Usage:${NC} $0 remote_host [remote_user]"
    echo "  remote_host: The hostname or IP address of the remote server"
    echo "  remote_user: The username on the remote server (optional, defaults to current user)"
    echo -e "${BLUE}Example:${NC} $0 192.168.1.100 admin"
}

# Check if remote host is provided
if [ $# -lt 1 ]; then
    show_usage
    exit 1
fi

REMOTE_HOST="$1"
REMOTE_USER="${2:-$(whoami)}"
LOCAL_USERNAME="$(whoami)"
USER_HOME="$HOME"

echo -e "${BLUE}=== SSH Root Access Setup ===${NC}"
echo -e "This script will set up SSH key authentication from ${GREEN}$LOCAL_USERNAME${NC} to ${RED}root@$REMOTE_HOST${NC}"

# Function to check if a command exists
command_exists() {
    command -v "$1" &> /dev/null
}

# Function to setup SSH directory with correct permissions
setup_ssh_directory() {
    echo -e "\n${BLUE}Setting up local .ssh directory...${NC}"
    mkdir -p "$USER_HOME/.ssh"
    chmod 700 "$USER_HOME/.ssh"
}

# Function to check for existing SSH keys
check_existing_keys() {
    if [ -f "$USER_HOME/.ssh/id_rsa" ]; then
        echo -e "${YELLOW}SSH key already exists at $USER_HOME/.ssh/id_rsa${NC}"
        read -p "Use existing key? (y/n): " use_existing
        if [[ "$use_existing" =~ ^[Yy]$ ]]; then
            return 0
        fi
    fi
    return 1
}

# Function to generate new SSH key pair
generate_ssh_keys() {
    echo -e "\n${BLUE}Generating new SSH key pair...${NC}"
    ssh-keygen -t rsa -b 4096 -f "$USER_HOME/.ssh/id_rsa"
    
    if [ $? -ne 0 ]; then
        echo -e "${RED}Error: Failed to generate SSH keys${NC}"
        exit 1
    fi
}

# Function to test SSH connection
test_ssh_connection() {
    local user=$1
    local host=$2
    
    echo -e "\n${BLUE}Testing SSH connection to $user@$host...${NC}"
    ssh -o PasswordAuthentication=no -o BatchMode=yes -o ConnectTimeout=5 "$user@$host" exit &>/dev/null
    
    return $?
}

# Function to copy key to remote user
copy_key_to_user() {
    echo -e "\n${BLUE}Copying your SSH key to $REMOTE_USER@$REMOTE_HOST...${NC}"
    
    if command_exists ssh-copy-id; then
        ssh-copy-id "$REMOTE_USER@$REMOTE_HOST"
        return $?
    else
        echo -e "${YELLOW}ssh-copy-id not found. Using manual method.${NC}"
        cat "$USER_HOME/.ssh/id_rsa.pub" | ssh "$REMOTE_USER@$REMOTE_HOST" "mkdir -p ~/.ssh && chmod 700 ~/.ssh && cat >> ~/.ssh/authorized_keys && chmod 600 ~/.ssh/authorized_keys"
        return $?
    fi
}

# Function to try direct root key setup
try_direct_root_setup() {
    echo -e "\n${BLUE}Attempting direct key setup to root@$REMOTE_HOST...${NC}"
    echo -e "${YELLOW}Note: This will only work if root SSH login with password is enabled${NC}"
    
    if command_exists ssh-copy-id; then
        ssh-copy-id "root@$REMOTE_HOST"
        return $?
    else
        echo -e "${YELLOW}ssh-copy-id not found. Using manual method.${NC}"
        cat "$USER_HOME/.ssh/id_rsa.pub" | ssh "root@$REMOTE_HOST" "mkdir -p /root/.ssh && chmod 700 /root/.ssh && cat >> /root/.ssh/authorized_keys && chmod 600 /root/.ssh/authorized_keys"
        return $?
    fi
}

# Function to set up root access via sudo
setup_root_via_sudo() {
    echo -e "\n${BLUE}Setting up root access via sudo...${NC}"
    echo -e "${YELLOW}You'll need to enter your sudo password on the remote server.${NC}"
    
    # Try using sudo with -S option to read password from stdin
    echo -e "${BLUE}Attempting automated setup...${NC}"
    read -sp "Enter sudo password for $REMOTE_USER@$REMOTE_HOST: " SUDO_PASS
    echo
    
    # Use here-string to provide password to sudo
    ssh "$REMOTE_USER@$REMOTE_HOST" "echo '$SUDO_PASS' | sudo -S mkdir -p /root/.ssh && echo '$SUDO_PASS' | sudo -S chmod 700 /root/.ssh && cat ~/.ssh/authorized_keys | sudo -S tee -a /root/.ssh/authorized_keys > /dev/null && echo '$SUDO_PASS' | sudo -S chmod 600 /root/.ssh/authorized_keys"
    
    if [ $? -eq 0 ]; then
        echo -e "${GREEN}Root access setup completed successfully!${NC}"
        return 0
    else
        echo -e "${YELLOW}Automated setup failed. Let's try manual steps.${NC}"
        echo -e "\n${BLUE}Please SSH to the remote server and run these commands:${NC}"
        echo -e "${GREEN}ssh $REMOTE_USER@$REMOTE_HOST${NC}"
        echo "sudo mkdir -p /root/.ssh"
        echo "sudo chmod 700 /root/.ssh"
        echo "cat ~/.ssh/authorized_keys | sudo tee -a /root/.ssh/authorized_keys"
        echo "sudo chmod 600 /root/.ssh/authorized_keys"
        echo "exit"
        
        read -p "Have you completed these steps? (y/n): " completed
        if [[ "$completed" =~ ^[Yy]$ ]]; then
            return 0
        else
            return 1
        fi
    fi
}

# Main execution
setup_ssh_directory

# Check for existing keys or generate new ones
if ! check_existing_keys; then
    generate_ssh_keys
fi

# First try direct root access
echo -e "\n${BLUE}Checking if direct root SSH access is enabled...${NC}"
if test_ssh_connection "root" "$REMOTE_HOST"; then
    echo -e "${GREEN}You already have key-based SSH access to root@$REMOTE_HOST!${NC}"
else
    # Try direct root key setup
    if try_direct_root_setup; then
        echo -e "${GREEN}Direct root key setup successful!${NC}"
    else
        echo -e "${YELLOW}Direct root access setup failed. Trying via regular user...${NC}"
        
        # Copy key to regular user first
        if ! copy_key_to_user; then
            echo -e "${RED}Failed to copy key to $REMOTE_USER@$REMOTE_HOST${NC}"
            exit 1
        fi
        
        # Now set up root access via sudo
        if ! setup_root_via_sudo; then
            echo -e "${RED}Failed to set up root access. Please check sudo privileges.${NC}"
            exit 1
        fi
    fi
fi

# Final test
echo -e "\n${BLUE}Testing connection to root@$REMOTE_HOST...${NC}"
if test_ssh_connection "root" "$REMOTE_HOST"; then
    echo -e "${GREEN}Success! You can now connect to root@$REMOTE_HOST using your SSH key.${NC}"
    echo -e "\n${BLUE}To connect, simply run:${NC}"
    echo -e "${GREEN}ssh root@$REMOTE_HOST${NC}"
    
    # Optional: Add to SSH config
    echo -e "\n${BLUE}Would you like to add this connection to your SSH config for easier access?${NC}"
    read -p "Add to SSH config? (y/n): " add_config
    if [[ "$add_config" =~ ^[Yy]$ ]]; then
        read -p "Enter a nickname for this server (e.g., 'production'): " server_nickname
        if [ -n "$server_nickname" ]; then
            echo -e "\nHost $server_nickname\n    HostName $REMOTE_HOST\n    User root\n    IdentityFile $USER_HOME/.ssh/id_rsa" >> "$USER_HOME/.ssh/config"
            chmod 600 "$USER_HOME/.ssh/config"
            echo -e "${GREEN}Added to SSH config. You can now connect using:${NC}"
            echo -e "${GREEN}ssh $server_nickname${NC}"
        fi
    fi
    
    echo -e "\n${YELLOW}Security Recommendations:${NC}"
    echo "1. Consider using a non-root user with sudo privileges instead of direct root login"
    echo "2. Disable password authentication in SSH after confirming key auth works"
    echo "3. Consider using a passphrase for your SSH key"
else
    echo -e "${RED}Connection test failed. Please check the setup manually.${NC}"
    exit 1
fi

exit 0
