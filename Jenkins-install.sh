#!/bin/bash

set -e

# --- Helper Functions ---

log() {
    echo -e "\033[1;34m[INFO]\033[0m $1"
}

error_exit() {
    echo -e "\033[1;31m[ERROR]\033[0m $1" >&2
    exit 1
}

show_jenkins_password() {
    log "Fetching Jenkins initial admin password..."
    if [ -f /var/lib/jenkins/secrets/initialAdminPassword ]; then
        sudo cat /var/lib/jenkins/secrets/initialAdminPassword
        ip_addr=$(hostname -I | awk '{print $1}')
        echo -e "\nJenkins is ready at: http://$ip_addr:8080"
    else
        error_exit "Initial admin password file not found."
    fi
}

install_debian_family() {
    log "Detected Debian/Ubuntu system"

    export DEBIAN_FRONTEND=noninteractive

    log "Updating system packages..."
    sudo apt update && sudo apt upgrade -y

    log "Installing Java and required packages..."
    sudo apt install -y openjdk-11-jdk wget curl gnupg

    log "Adding Jenkins GPG key and repo..."
    curl -fsSL https://pkg.jenkins.io/debian-stable/jenkins.io-2023.key | sudo tee /usr/share/keyrings/jenkins-keyring.asc > /dev/null
    echo "deb [signed-by=/usr/share/keyrings/jenkins-keyring.asc] https://pkg.jenkins.io/debian-stable binary/" | \
        sudo tee /etc/apt/sources.list.d/jenkins.list > /dev/null

    sudo apt update
    sudo apt install -y jenkins

    sudo systemctl enable --now jenkins

    show_jenkins_password
}

install_fedora_family() {
    log "Detected Fedora/CentOS/RHEL system"

    log "Updating system packages..."
    sudo dnf upgrade -y

    log "Installing Java and required packages..."
    sudo dnf install -y java-11-openjdk-devel wget curl

    log "Adding Jenkins repo and GPG key..."
    sudo curl -o /etc/yum.repos.d/jenkins.repo https://pkg.jenkins.io/redhat-stable/jenkins.repo
    sudo rpm --import https://pkg.jenkins.io/redhat-stable/jenkins.io.key

    sudo dnf install -y jenkins

    sudo systemctl enable --now jenkins

    show_jenkins_password
}

# --- OS Detection ---

if [ -f /etc/os-release ]; then
    . /etc/os-release

    case "$ID" in
        ubuntu|debian)
            install_debian_family
            ;;
        fedora|rhel|centos|rocky|almalinux)
            install_fedora_family
            ;;
        *)
            error_exit "Unsupported OS: $ID"
            ;;
    esac
else
    error_exit "/etc/os-release not found — cannot determine OS."
fi

