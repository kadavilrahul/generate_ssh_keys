#!/bin/bash

# Configuration
DEST_SERVER_IP="your_ip_address"
DEST_SERVER_PASSWORD="your_password"
PROGRESS_FILE="/tmp/ssh_setup_progress"

# Color codes for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Logging functions
log_message() { echo -e "[$(date '+%Y-%m-%d %H:%M:%S')] $1"; }
log_success() { echo -e "[$(date '+%Y-%m-%d %H:%M:%S')] ${GREEN}$1${NC}"; }
log_warning() { echo -e "[$(date '+%Y-%m-%d %H:%M:%S')] ${YELLOW}WARNING: $1${NC}"; }
log_error() { echo -e "[$(date '+%Y-%m-%d %H:%M:%S')] ${RED}ERROR: $1${NC}" >&2; }

# Function to handle errors
error_exit() {
    log_error "$1"
    exit 1
}

# Function to check if a step is completed
is_step_completed() {
    local step=$1
    [ -f "$PROGRESS_FILE" ] && grep -q "^$step$" "$PROGRESS_FILE"
}

# Function to mark a step as completed
mark_step_completed() {
    local step=$1
    echo "$step" >> "$PROGRESS_FILE"
}

# Function to ask if a step should be executed
ask_step() {
    local step=$1
    local description=$2
    
    if is_step_completed "$step"; then
        log_message "$description - Already completed"
        return 1
    fi
    
    log_message "$description - Starting..."
    return 0
}

# Function to check root privileges
check_root() {
    if [ "$EUID" -ne 0 ]; then 
        error_exit "Please run as root"
    fi
}

# Function to check required tools
check_requirements() {
    local tools="ssh ssh-keygen ssh-copy-id sshpass"
    
    for tool in $tools; do
        if ! command -v "$tool" &>/dev/null; then
            error_exit "$tool is required but not installed"
        fi
    done
}

# Function to setup SSH directory
setup_ssh_dir() {
    if [ ! -d ~/.ssh ]; then
        mkdir -p ~/.ssh
        chmod 700 ~/.ssh
    fi
}

# Function to setup SSH keys
setup_ssh() {
    if ask_step "setup_ssh" "Setup SSH Keys"; then
        log_message "Setting up SSH access to destination server..."
        
        # Remove old host key if exists
        ssh-keygen -f "$HOME/.ssh/known_hosts" -R "$DEST_SERVER_IP" 2>/dev/null || true
        
        # Generate key pair if not exists
        if [ ! -f ~/.ssh/id_rsa ]; then
            ssh-keygen -t rsa -b 4096 -f ~/.ssh/id_rsa -N '' || \
                error_exit "Failed to generate SSH key"
        fi
        
        # Copy public key to destination server using sshpass
        sshpass -p "$DEST_SERVER_PASSWORD" ssh-copy-id -o StrictHostKeyChecking=no -i ~/.ssh/id_rsa.pub "root@$DEST_SERVER_IP" || \
            error_exit "Failed to copy SSH key to destination server"
        
        # Test connection
        if ssh -o BatchMode=yes -o StrictHostKeyChecking=no "root@$DEST_SERVER_IP" 'echo test' >/dev/null 2>&1; then
            log_success "SSH key-based authentication configured successfully"
            mark_step_completed "setup_ssh"
        else
            error_exit "SSH key setup failed. Please check server connectivity"
        fi
    else
        log_message "Skipping SSH setup"
    fi
}

# Function to verify SSH connection
verify_ssh() {
    log_message "Verifying SSH connection..."
    if ssh -o BatchMode=yes -o ConnectTimeout=5 "root@$DEST_SERVER_IP" 'echo test' >/dev/null 2>&1; then
        log_success "SSH connection verified successfully"
        return 0
    else
        log_warning "SSH connection verification failed"
        return 1
    fi
}

# Function to clean progress
clean_progress() {
    if [ -f "$PROGRESS_FILE" ]; then
        log_message "Cleaning up previous progress..."
        rm -f "$PROGRESS_FILE"
    fi
}

# Main function
main() {
    check_root
    check_requirements
    setup_ssh_dir
    
    # First try to verify existing connection
    if ! verify_ssh; then
        # If verification fails, clean progress and try setup again
        clean_progress
        setup_ssh
        
        # Verify again after new setup
        if ! verify_ssh; then
            error_exit "SSH setup failed. Please check server connectivity and credentials"
        fi
    fi
    
    log_success "SSH setup completed successfully"
}

# Execute main function
main "$@"
