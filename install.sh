#!/bin/bash

set -e  # Exit on any error

# Tool variables
TOOL_GIT="git"
TOOL_JAVA_YUM="java-17-amazon-corretto-devel"
TOOL_JAVA_APT="openjdk-17-jdk"
TOOL_NGINX="nginx"
TOOL_DOCKER="docker"
TOOL_NODEJS="nodejs"
TOOL_NODEJS_SETUP_RPM="https://rpm.nodesource.com/setup_18.x"
TOOL_NODEJS_SETUP_DEB="https://deb.nodesource.com/setup_18.x"

# Logging function
log() {
    echo -e "\n====> $1\n"
}

# Detect OS
if [ -f /etc/os-release ]; then
    . /etc/os-release
    OS_ID=$ID
    log "Detected OS: $OS_ID"
else
    log "Cannot detect OS. /etc/os-release not found."
    exit 1
fi

# --- Amazon Linux / CentOS ---
if [[ "$OS_ID" == "amzn" || "$OS_ID" == "centos" ]]; then
    log "Running YUM-based installation..."

    sudo yum update -y
    sudo yum upgrade -y

    log "Installing $TOOL_GIT"
    sudo yum install -y "$TOOL_GIT"

    log "Installing Java ($TOOL_JAVA_YUM)"
    sudo yum install -y "$TOOL_JAVA_YUM"
    JAVA_PATH=$(dirname $(dirname $(readlink -f $(which java))))
    echo "export JAVA_HOME=$JAVA_PATH" >> ~/.bashrc
    echo "export PATH=\$PATH:\$JAVA_HOME/bin" >> ~/.bashrc
    source ~/.bashrc

    log "Installing $TOOL_NGINX"
    sudo amazon-linux-extras enable nginx1 || true
    sudo yum install -y "$TOOL_NGINX"
    sudo systemctl enable nginx
    sudo systemctl start nginx

    log "Installing $TOOL_DOCKER"
    sudo yum install -y "$TOOL_DOCKER"
    sudo systemctl enable docker
    sudo systemctl start docker
    sudo usermod -aG docker "$USER"

    log "Installing $TOOL_NODEJS"
    curl -sL "$TOOL_NODEJS_SETUP_RPM" | sudo bash -
    sudo yum install -y "$TOOL_NODEJS"

# --- Ubuntu ---
elif [[ "$OS_ID" == "ubuntu" ]]; then
    log "Running APT-based installation..."

    sudo apt update -y
    sudo apt upgrade -y

    log "Installing $TOOL_GIT"
    sudo apt install -y "$TOOL_GIT"

    log "Installing Java ($TOOL_JAVA_APT)"
    sudo apt install -y "$TOOL_JAVA_APT"
    JAVA_PATH=$(dirname $(dirname $(readlink -f $(which java))))
    echo "export JAVA_HOME=$JAVA_PATH" >> ~/.bashrc
    echo "export PATH=\$PATH:\$JAVA_HOME/bin" >> ~/.bashrc
    source ~/.bashrc

    log "Installing $TOOL_NGINX"
    sudo apt install -y "$TOOL_NGINX"
    sudo systemctl enable nginx
    sudo systemctl start nginx

    log "Installing $TOOL_DOCKER"
    sudo apt install -y "$TOOL_DOCKER.io"
    sudo systemctl enable docker
    sudo systemctl start docker
    sudo usermod -aG docker "$USER"

    log "Installing $TOOL_NODEJS"
    curl -fsSL "$TOOL_NODEJS_SETUP_DEB" | sudo -E bash -
    sudo apt install -y "$TOOL_NODEJS"

# --- Unsupported OS ---
else
    log "Unsupported OS: $OS_ID"
    exit 1
fi

# --- Verification ---
log "Verifying installed versions:"
git --version || true
java --version || true
nginx -v || true
docker --version || true
node -v || true
npm -v || true

log "✅ Installation completed successfully on $OS_ID!"

