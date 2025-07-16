#!/bin/bash

set -e

# Function to display the Jenkins initial admin password
show_jenkins_password() {
    echo -e "\nFetching Jenkins initial admin password..."
    if [ -f /var/lib/jenkins/secrets/initialAdminPassword ]; then
        sudo cat /var/lib/jenkins/secrets/initialAdminPassword
        echo -e "\nYou can now access Jenkins at: http://<your_server_ip>:8080"
    else
        echo "Could not find the Jenkins initial admin password file."
    fi
}

# Function for Debian/Ubuntu systems
install_jenkins_debian() {
    echo "Detected Debian/Ubuntu system."
    sudo apt update
    sudo apt install -y openjdk-11-jdk wget gnupg

    # Add Jenkins key and repository
    wget -q -O - https://pkg.jenkins.io/debian-stable/jenkins.io.key | sudo tee /usr/share/keyrings/jenkins-keyring.asc > /dev/null
    echo deb [signed-by=/usr/share/keyrings/jenkins-keyring.asc] https://pkg.jenkins.io/debian-stable binary/ | sudo tee /etc/apt/sources.list.d/jenkins.list > /dev/null

    sudo apt update
    sudo apt install -y jenkins

    sudo systemctl enable jenkins
    sudo systemctl start jenkins

    show_jenkins_password
}

# Function for RHEL/CentOS/Fedora systems
install_jenkins_rhel() {
    echo "Detected RHEL/CentOS/Fedora system."
    sudo yum install -y java-11-openjdk-devel wget

    sudo wget -O /etc/yum.repos.d/jenkins.repo https://pkg.jenkins.io/redhat-stable/jenkins.repo
    sudo rpm --import https://pkg.jenkins.io/redhat-stable/jenkins.io.key

    sudo yum install -y jenkins

    sudo systemctl enable jenkins
    sudo systemctl start jenkins

    show_jenkins_password
}

# Detect OS and call appropriate install function
if [ -f /etc/os-release ]; then
    . /etc/os-release
    case "$ID" in
        ubuntu|debian)
            install_jenkins_debian
            ;;
        centos|rhel|fedora)
            install_jenkins_rhel
            ;;
        *)
            echo "Unsupported Linux distribution: $ID"
            exit 1
            ;;
    esac
else
    echo "Cannot detect OS. /etc/os-release not found."
    exit 1
fi
