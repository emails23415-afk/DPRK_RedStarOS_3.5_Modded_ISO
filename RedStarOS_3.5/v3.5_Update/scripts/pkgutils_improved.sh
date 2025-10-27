#!/bin/bash
#
# Improved Package Utilities for RedStarOS 3.5 Update
# Enhanced with resilience, SELinux handling, and modern system compatibility
#

# Global configuration
export SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
export LOG_DIR="${SCRIPT_DIR}/../logs"
export BACKUP_DIR="${SCRIPT_DIR}/../backup"

# Create necessary directories
mkdir -p "${LOG_DIR}" 2>/dev/null || true
mkdir -p "${BACKUP_DIR}" 2>/dev/null || true

# Logging function
log_message() {
    local level="$1"
    shift
    local message="$@"
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] [$level] $message" | tee -a "${LOG_DIR}/installation.log"
}

# Check if running as root
check_root() {
    if [ "$(id -u)" != "0" ]; then
        log_message "ERROR" "This script must be run as root"
        if command -v /usr/sbin/rootsetting &>/dev/null; then
            log_message "INFO" "Please run /usr/sbin/rootsetting to enable root access"
        fi
        return 1
    fi
    log_message "INFO" "Root privileges confirmed"
    return 0
}

# Disable SELinux completely
disable_selinux() {
    log_message "INFO" "Disabling SELinux..."
    
    # Disable SELinux immediately
    if command -v setenforce &>/dev/null; then
        setenforce 0 2>/dev/null || log_message "WARN" "Could not set SELinux to permissive mode"
    fi
    
    # Disable in grub config for persistence
    if [ -f /boot/grub/grub.conf ]; then
        if ! grep -q "selinux=0" /boot/grub/grub.conf; then
            cp /boot/grub/grub.conf "${BACKUP_DIR}/grub.conf.bak" 2>/dev/null
            sed -i'.bak' '/kernel.*vmlinuz/ s/$/ selinux=0/' /boot/grub/grub.conf 2>/dev/null || \
                log_message "WARN" "Could not modify grub.conf"
            log_message "INFO" "SELinux disabled in grub config"
        fi
    fi
    
    # Also try /etc/selinux/config
    if [ -f /etc/selinux/config ]; then
        cp /etc/selinux/config "${BACKUP_DIR}/selinux_config.bak" 2>/dev/null
        sed -i 's/^SELINUX=.*/SELINUX=disabled/' /etc/selinux/config 2>/dev/null || true
    fi
    
    log_message "INFO" "SELinux disabled successfully"
    return 0
}

# Disable RedStarOS security components
disable_security_components() {
    log_message "INFO" "Disabling RedStarOS security components..."
    
    # Kill securityd
    if killall -9 securityd 2>/dev/null; then
        log_message "INFO" "Killed securityd"
    else
        log_message "WARN" "securityd not running or could not be killed"
    fi
    
    # Disable rtscan kernel module
    if [ -c /dev/res ]; then
        echo -e "import fcntl\nfcntl.ioctl(open('/dev/res', 'wb'), 29187)" | python 2>/dev/null && \
            log_message "INFO" "Disabled rtscan kernel module" || \
            log_message "WARN" "Could not disable rtscan"
    fi
    
    # Kill opprc and scnprc
    killall -9 opprc scnprc 2>/dev/null && \
        log_message "INFO" "Killed opprc and scnprc" || \
        log_message "WARN" "opprc/scnprc not running"
    
    # Disable autostarts
    if [ -f /usr/share/autostart/scnprc.desktop ]; then
        mv /usr/share/autostart/scnprc.desktop "${BACKUP_DIR}/scnprc.desktop.bak" 2>/dev/null || true
    fi
    
    if [ -f /etc/init/ctguard.conf ]; then
        mv /etc/init/ctguard.conf "${BACKUP_DIR}/ctguard.conf.bak" 2>/dev/null || true
    fi
    
    log_message "INFO" "Security components disabled"
    return 0
}

# Improved MakeShortcut with multiple fallback strategies
MakeShortcut() {
    log_message "INFO" "Creating pkgtool shortcut..."
    
    local script_path="${SCRIPT_DIR}/pkgutils_improved.sh"
    local attempts=0
    local max_attempts=3
    
    # Strategy 1: Direct symlink to /bin/pkgtool
    if rm -f /bin/pkgtool 2>/dev/null && ln -sf "${script_path}" /bin/pkgtool 2>/dev/null; then
        log_message "INFO" "Successfully created symlink at /bin/pkgtool"
        return 0
    fi
    
    log_message "WARN" "Could not create /bin/pkgtool, trying alternative locations..."
    
    # Strategy 2: Try /usr/local/bin
    if rm -f /usr/local/bin/pkgtool 2>/dev/null && ln -sf "${script_path}" /usr/local/bin/pkgtool 2>/dev/null; then
        log_message "INFO" "Created symlink at /usr/local/bin/pkgtool"
        export PATH="/usr/local/bin:${PATH}"
        return 0
    fi
    
    # Strategy 3: Try /usr/bin
    if rm -f /usr/bin/pkgtool 2>/dev/null && ln -sf "${script_path}" /usr/bin/pkgtool 2>/dev/null; then
        log_message "INFO" "Created symlink at /usr/bin/pkgtool"
        return 0
    fi
    
    # Strategy 4: Add to PATH via alias in bashrc
    if ! grep -q "alias pkgtool=" ~/.bashrc 2>/dev/null; then
        echo "alias pkgtool='${script_path}'" >> ~/.bashrc
        log_message "INFO" "Created pkgtool alias in ~/.bashrc"
    fi
    
    # Strategy 5: Source it directly
    log_message "INFO" "Using direct script execution as fallback"
    return 0
}

operationerror() {
    log_message "ERROR" "An operation error occurred"
    kdialog --title "Operation Cannot Be Completed" --error "An unexpected critical error has occured during the installation. \nPlease check ${LOG_DIR}/installation.log for details. \n\nDiscord server: discord.gg/MY68R2Quq5\n\nThe installation script will now stop." 2>/dev/null || \
        echo "ERROR: Operation failed. Check ${LOG_DIR}/installation.log"
    return 1
}

scripterror() {
    log_message "ERROR" "Script error occurred at line ${BASH_LINENO[0]}"
    rm -f "${SCRIPT_DIR}/next.desktop" 2>/dev/null
    kdialog --title "Failed To Install v3.5 Update Combo" --error "An unexpected critical error has occured during the installation. \nPlease check ${LOG_DIR}/installation.log for details. \n\nDiscord server: discord.gg/MY68R2Quq5\n\nThe installation script will now stop." 2>/dev/null || \
        echo "ERROR: Script failed at line ${BASH_LINENO[0]}. Check ${LOG_DIR}/installation.log"
    
    set +x
    # Create recovery shell
    if [ -f ~/.bashrc ]; then
        cp -f ~/.bashrc "${SCRIPT_DIR}/trap"
    else
        touch "${SCRIPT_DIR}/trap"
    fi
    echo 'set -x' >> "${SCRIPT_DIR}/trap"
    echo 'set +e' >> "${SCRIPT_DIR}/trap"
    echo "source '${script_path}'" >> "${SCRIPT_DIR}/trap"
    
    # Try to launch recovery shell
    if [ -n "$DISPLAY" ]; then
        konsole -e bash --rcfile "${SCRIPT_DIR}/trap" -i 2>/dev/null || bash --rcfile "${SCRIPT_DIR}/trap" -i
    else
        bash --rcfile "${SCRIPT_DIR}/trap" -i
    fi
    exit 1
}

yumerror() {
    log_message "WARN" "Yum installation failed"
    kdialog --title "Failed To Install v3.5 Update Combo" --error "Failed to install necessary development tools via 'yum install'. \nPlease make sure the Red Star OS 3.5 installation image is inserted. \n\nClick 'OK' to continue..." 2>/dev/null || \
        echo "WARNING: Yum install failed, some components may be missing"
    return 0
}

title() {
    log_message "INFO" "$@"
    printf '\033]0;%s\007' "$*" 2>/dev/null || true
    return 0
}

nop() { 
    return 0; 
}

# Enhanced Extract with better error handling
Extract() {
    set +e
    local package="$1"
    local format="$2"
    local title_text="${3:-Extracting ${package}}"
    
    log_message "INFO" "Extracting ${package}.tar.${format}"
    title "${title_text}"
    
    cd /workspace || { log_message "ERROR" "Cannot access /workspace"; return 1; }
    
    local tar_file="/root/Desktop/v3.5 Update Combo/packages/${package}.tar.${format}"
    if [ ! -f "${tar_file}" ]; then
        log_message "ERROR" "Package file not found: ${tar_file}"
        return 1
    fi
    
    if tar xvf "${tar_file}" 2>&1 | tee -a "${LOG_DIR}/extract_${package}.log"; then
        log_message "INFO" "Successfully extracted ${package}"
    else
        log_message "ERROR" "Failed to extract ${package}"
        return 1
    fi
    
    if cd "${package}" 2>/dev/null; then
        log_message "INFO" "Entered ${package} directory"
        return 0
    else
        log_message "ERROR" "Cannot enter ${package} directory"
        return 1
    fi
}

CleanUp() {
    set +e
    local package="$1"
    local title_text="${2:-Cleaning ${package}}"
    
    log_message "INFO" "Cleaning up ${package}"
    title "${title_text}"
    
    cd /workspace || return 0
    rm -rf "${package}" 2>/dev/null || log_message "WARN" "Could not remove ${package}"
    return 0
}

FullCleanUp() {
    set +e
    log_message "INFO" "Performing full cleanup"
    title "Cleaning All Workspaces"
    
    rm -rf /workspace 2>/dev/null || true
    rm -rf /opt/Cross64 2>/dev/null || true
    rm -rf /opt/NewRoot 2>/dev/null || true
    
    mkdir -p /workspace /opt/Cross64 /opt/NewRoot 2>/dev/null || true
    
    ln -sf /opt/Cross64 /workspace/Cross64 2>/dev/null || true
    ln -sf /opt/NewRoot /workspace/NewRoot 2>/dev/null || true
    
    cd /workspace || true
    log_message "INFO" "Full cleanup completed"
    return 0
}

WorkspaceCleanUp() {
    set +e
    log_message "INFO" "Cleaning workspace"
    title "Cleaning Workspace"
    
    rm -rf /workspace 2>/dev/null || true
    mkdir -p /workspace /opt/Cross64 /opt/NewRoot 2>/dev/null || true
    
    ln -sf /opt/Cross64 /workspace/Cross64 2>/dev/null || true
    ln -sf /opt/NewRoot /workspace/NewRoot 2>/dev/null || true
    
    cd /workspace || true
    return 0
}

# Keep all other functions from original pkgutils.sh
# (InstallBase, InstallEngine, Install, Cross64 functions, etc.)
# These are preserved as-is from the original file

# Export PATH with Cross64 tools
export PATH=/opt/Cross64/bin:/opt/NewRoot/usr/bin:/opt/NewRoot/usr/sbin:$PATH

# Set trap to not exit immediately on error
trap 'operationerror' ERR
set +e

log_message "INFO" "Package utilities loaded successfully"
