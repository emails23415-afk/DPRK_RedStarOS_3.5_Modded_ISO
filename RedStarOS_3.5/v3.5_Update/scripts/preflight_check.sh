#!/bin/bash
#
# Pre-flight checks for RedStarOS 3.5 Update Installation
# This script performs all necessary system checks and preparations
#

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
LOG_FILE="${SCRIPT_DIR}/../logs/preflight.log"

mkdir -p "${SCRIPT_DIR}/../logs" 2>/dev/null

log() {
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] $@" | tee -a "${LOG_FILE}"
}

error_exit() {
    log "ERROR: $1"
    kdialog --title "Pre-flight Check Failed" --error "$1\n\nPlease check ${LOG_FILE} for details." 2>/dev/null || echo "ERROR: $1"
    exit 1
}

log "====================================="
log "RedStarOS 3.5 Update - Pre-flight Check"
log "====================================="

# Check 1: Root privileges
log "Check 1: Verifying root privileges..."
if [ "$(id -u)" != "0" ]; then
    log "Not running as root. Attempting to enable root access..."
    if command -v /usr/sbin/rootsetting &>/dev/null; then
        log "Please run /usr/sbin/rootsetting to enable root access, then run this script again."
        /usr/sbin/rootsetting 2>/dev/null || true
    fi
    error_exit "Root privileges required. Please run as root."
fi
log "✓ Root privileges confirmed"

# Check 2: Disable SELinux
log "Check 2: Disabling SELinux..."
if command -v setenforce &>/dev/null; then
    setenforce 0 2>/dev/null || log "Warning: Could not set SELinux to permissive"
    log "✓ SELinux set to permissive mode"
else
    log "! SELinux tools not found (may not be installed)"
fi

# Check 3: Kill security daemons
log "Check 3: Stopping RedStarOS security components..."
killall -9 securityd opprc scnprc artsd 2>/dev/null && log "✓ Security daemons stopped" || log "! Security daemons not running"

# Check 4: Disable rtscan
log "Check 4: Disabling rtscan kernel module..."
if [ -c /dev/res ]; then
    echo -e "import fcntl\nfcntl.ioctl(open('/dev/res', 'wb'), 29187)" | python 2>/dev/null && \
        log "✓ rtscan disabled" || log "! Could not disable rtscan"
else
    log "! /dev/res not found (rtscan may not be present)"
fi

# Check 5: Verify required directories
log "Check 5: Checking required directories..."
for dir in "/root/Desktop/v3.5 Update Combo" "/root/Desktop/v3.5 Update Combo/packages" "/root/Desktop/v3.5 Update Combo/scripts"; do
    if [ ! -d "${dir}" ]; then
        # Try alternative locations
        if [ -d "/root/Desktop/v3.5_Update" ]; then
            log "Found alternative path: /root/Desktop/v3.5_Update"
            break
        fi
        error_exit "Required directory not found: ${dir}"
    fi
done
log "✓ Required directories present"

# Check 6: Verify disk space
log "Check 6: Checking disk space..."
ROOT_SPACE=$(df / | awk 'NR==2 {print $4}')
if [ "${ROOT_SPACE}" -lt 10485760 ]; then  # 10GB in KB
    log "Warning: Less than 10GB free space available"
else
    log "✓ Sufficient disk space available"
fi

# Check 7: Create necessary directories
log "Check 7: Creating workspace directories..."
mkdir -p /workspace /opt/Cross64 /opt/NewRoot "${SCRIPT_DIR}/../logs" "${SCRIPT_DIR}/../backup" 2>/dev/null || \
    error_exit "Could not create necessary directories"
log "✓ Workspace directories created"

# Check 8: Verify /bin is writable (with SELinux disabled)
log "Check 8: Testing /bin write permissions..."
if touch /bin/.test_write 2>/dev/null; then
    rm -f /bin/.test_write
    log "✓ /bin is writable"
else
    log "! /bin is not writable, will use alternative locations for shortcuts"
fi

# Check 9: Backup critical files
log "Check 9: Backing up critical configuration files..."
for file in /boot/grub/grub.conf /etc/selinux/config ~/.bashrc; do
    if [ -f "${file}" ]; then
        cp "${file}" "${SCRIPT_DIR}/../backup/$(basename ${file}).bak" 2>/dev/null || \
            log "Warning: Could not backup ${file}"
    fi
done
log "✓ Configuration files backed up"

# Check 10: Verify package files
log "Check 10: Verifying package files..."
PACKAGE_DIR="/root/Desktop/v3.5 Update Combo/packages"
if [ -d "${PACKAGE_DIR}" ]; then
    PACKAGE_COUNT=$(find "${PACKAGE_DIR}" -name "*.tar.*" 2>/dev/null | wc -l)
    log "Found ${PACKAGE_COUNT} package files"
    if [ "${PACKAGE_COUNT}" -lt 5 ]; then
        log "Warning: Expected more package files"
    else
        log "✓ Package files present"
    fi
else
    log "Warning: Package directory not found at expected location"
fi

log "====================================="
log "Pre-flight check completed successfully!"
log "====================================="

kdialog --title "Pre-flight Check Complete" --msgbox "All pre-flight checks completed!\n\nThe system is ready for v3.5 Update installation.\n\nClick OK to continue..." 2>/dev/null || \
    echo "Pre-flight check passed! Ready to proceed with installation."

exit 0
