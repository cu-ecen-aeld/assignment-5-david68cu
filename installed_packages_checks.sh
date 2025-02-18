#!/bin/bash

# List of required packages with version constraints
REQUIRED_PACKAGES=(
    "which"
    "sed"
    "make>=3.81"
    "binutils"
    "build-essential"
    "diffutils"
    "gcc>=4.8"
    "g++>=4.8"
    "bash"
    "patch"
    "gzip"
    "bzip2"
    "perl>=5.8.7"
    "tar"
    "cpio"
    "unzip"
    "rsync"
    "file"
    "bc"
    "findutils"
)

# Function to check if a package is installed
is_installed() {
    dpkg -l | grep -E "^ii" | awk '{print $2}' | grep -x "$1" &>/dev/null
}

# Function to check if a package meets the version requirement
check_version() {
    local package_name=$1
    local required_version=$2
    local current_version=$(dpkg-query -W -f='${Version}' "$package_name" 2>/dev/null | cut -d'-' -f1)
    
    if [[ -z "$current_version" ]]; then
        return 1  # Not installed
    fi
    
    if dpkg --compare-versions "$current_version" ge "$required_version"; then
        return 0  # Meets version requirement
    else
        return 1  # Needs upgrade
    fi
}

# Ensure script runs as root
if [[ $EUID -ne 0 ]]; then
    echo "This script must be run as root. Use sudo." >&2
    exit 1
fi

# Update package list
apt update -y

# Loop through each required package
for pkg in "${REQUIRED_PACKAGES[@]}"; do
    
    # Extract package name and version if specified
    if [[ "$pkg" == *">="* ]]; then
        package_name=$(echo "$pkg" | cut -d'>' -f1)
        required_version=$(echo "$pkg" | cut -d'=' -f2)
    else
        package_name="$pkg"
        required_version=""
    fi
    
    # Check if installed and meets version requirements
    if [[ -n "$required_version" ]]; then
        if check_version "$package_name" "$required_version"; then
            echo "$package_name (version >= $required_version) is installed."
        else
            echo "$package_name (version >= $required_version) is missing or outdated. Installing..."
            apt install -y "$package_name"
        fi
    else
        if is_installed "$package_name"; then
            echo "$package_name is installed."
        else
            echo "$package_name is missing. Installing..."
            apt install -y "$package_name"
        fi
    fi

done

echo "All required packages are installed."

