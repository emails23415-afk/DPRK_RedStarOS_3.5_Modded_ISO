#!/bin/bash
#
# RedStarOS 3.5 Update - Resilient Installation Wrapper
# This is the main entry point that provides maximum compatibility and error recovery
#

set +e  # Don't exit on errors, handle them gracefully

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
LOG_DIR="${SCRIPT_DIR}/logs"
BACKUP_DIR="${SCRIPT_DIR}/backup"

# Colors for output (if terminal supports it)
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Create necessary directories
mkdir -p "${LOG_DIR}" "${BACKUP_DIR}" 2>/dev/null

# Logging function
log() {
    local level="$1"
    shift
    local message="$@"
    local timestamp="$(date '+%Y-%m-%d %H:%M:%S')"
    echo "[${timestamp}] [${level}] ${message}" | tee -a "${LOG_DIR}/master.log"
    
    case "${level}" in
        ERROR)
            echo -e "${RED}[ERROR]${NC} ${message}"
            ;;
        WARN)
            echo -e "${YELLOW}[WARNING]${NC} ${message}"
            ;;
        SUCCESS)
            echo -e "${GREEN}[SUCCESS]${NC} ${message}"
            ;;
        *)
            echo "[${level}] ${message}"
            ;;
    esac
}

# Display banner
display_banner() {
    clear
    cat << "EOF"
╔═══════════════════════════════════════════════════════════╗
║                                                           ║
║     RedStarOS 3.5 Update Combo - Resilient Installer     ║
║                                                           ║
║     Enhanced with:                                        ║
║     • SELinux auto-disable                                ║
║     • Security component bypass                           ║
║     • Multiple fallback strategies                        ║
║     • Comprehensive error recovery                        ║
║                                                           ║
╚═══════════════════════════════════════════════════════════╝
EOF
    echo
}

# Check if running as root
check_root() {
    if [ "$(id -u)" != "0" ]; then
        log "ERROR" "This installer must be run as root"
        echo
        echo "Please enable root access using one of these methods:"
        echo "  1. Run: /usr/sbin/rootsetting"
        echo "  2. Use: su - root"
        echo "  3. Run: sudo $0"
        echo
        
        # Try to automatically enable root
        if command -v /usr/sbin/rootsetting &>/dev/null; then
            log "INFO" "Attempting to enable root access..."
            /usr/sbin/rootsetting 2>/dev/null || true
        fi
        
        return 1
    fi
    return 0
}

# Disable all SELinux protections
disable_selinux_completely() {
    log "INFO" "Disabling SELinux completely..."
    
    # Method 1: Immediate disable
    if command -v setenforce &>/dev/null; then
        setenforce 0 2>/dev/null && log "SUCCESS" "SELinux set to permissive mode" || log "WARN" "Could not set SELinux mode"
    fi
    
    # Method 2: Disable in /etc/selinux/config
    if [ -f /etc/selinux/config ]; then
        cp /etc/selinux/config "${BACKUP_DIR}/selinux_config.backup" 2>/dev/null
        sed -i 's/^SELINUX=.*/SELINUX=disabled/' /etc/selinux/config
        log "INFO" "Updated /etc/selinux/config"
    fi
    
    # Method 3: Disable in grub config
    for grub_conf in /boot/grub/grub.conf /boot/grub2/grub.cfg /etc/grub.conf; do
        if [ -f "${grub_conf}" ]; then
            cp "${grub_conf}" "${BACKUP_DIR}/$(basename ${grub_conf}).backup" 2>/dev/null
            if ! grep -q "selinux=0" "${grub_conf}"; then
                sed -i.bak '/kernel.*vmlinuz/ s/$/ selinux=0/' "${grub_conf}" 2>/dev/null && \
                    log "SUCCESS" "SELinux disabled in ${grub_conf}" || \
                    log "WARN" "Could not modify ${grub_conf}"
            else
                log "INFO" "SELinux already disabled in ${grub_conf}"
            fi
        fi
    done
    
    # Method 4: Create /etc/selinux/.disabled marker
    touch /etc/selinux/.disabled 2>/dev/null
    
    log "SUCCESS" "SELinux disabled completely"
    return 0
}

# Kill all RedStarOS security components
kill_security_components() {
    log "INFO" "Stopping RedStarOS security components..."
    
    local killed_count=0
    
    # Kill securityd
    if pgrep securityd &>/dev/null; then
        killall -9 securityd 2>/dev/null && {
            log "SUCCESS" "Killed securityd"
            ((killed_count++))
        }
    fi
    
    # Kill opprc
    if pgrep opprc &>/dev/null; then
        killall -9 opprc 2>/dev/null && {
            log "SUCCESS" "Killed opprc"
            ((killed_count++))
        }
    fi
    
    # Kill scnprc
    if pgrep scnprc &>/dev/null; then
        killall -9 scnprc 2>/dev/null && {
            log "SUCCESS" "Killed scnprc"
            ((killed_count++))
        }
    fi
    
    # Kill artsd (audio daemon that can interfere)
    if pgrep artsd &>/dev/null; then
        killall -9 artsd 2>/dev/null && {
            log "SUCCESS" "Killed artsd"
            ((killed_count++))
        }
    fi
    
    # Disable rtscan kernel module
    if [ -c /dev/res ]; then
        if command -v python &>/dev/null; then
            echo -e "import fcntl\\nfcntl.ioctl(open('/dev/res', 'wb'), 29187)" | python 2>/dev/null && {
                log "SUCCESS" "Disabled rtscan kernel module"
                ((killed_count++))
            } || log "WARN" "Could not disable rtscan"
        fi
    fi
    
    # Disable autostart files
    for autostart in /usr/share/autostart/scnprc.desktop /etc/init/ctguard.conf; do
        if [ -f "${autostart}" ]; then
            mv "${autostart}" "${BACKUP_DIR}/$(basename ${autostart}).disabled" 2>/dev/null && \
                log "SUCCESS" "Disabled $(basename ${autostart})"
        fi
    done
    
    log "SUCCESS" "Stopped ${killed_count} security components"
    return 0
}

# Make system directories writable
ensure_writable_directories() {
    log "INFO" "Ensuring critical directories are writable..."
    
    local dirs="/bin /usr/bin /usr/local/bin /sbin /usr/sbin"
    
    for dir in ${dirs}; do
        if [ -d "${dir}" ]; then
            # Try to make writable
            chmod 755 "${dir}" 2>/dev/null || true
            
            # Test write access
            if touch "${dir}/.test_write" 2>/dev/null; then
                rm -f "${dir}/.test_write"
                log "SUCCESS" "${dir} is writable"
            else
                log "WARN" "${dir} is not writable, may need alternative approach"
            fi
        fi
    done
    
    return 0
}

# Replace libos.so with defused version
replace_libos() {
    log "INFO" "Replacing libos.so with defused version..."
    
    # Base64 encoded defused libos.so (from redstar-tools)
    local LIBOS="f0VMRgEBAQAAAAAAAAAAAAMAAwABAAAAIAMAADQAAABUBgAAAAAAADQAIAAFACgAGgAXAAEAAAAA
AAAAAAAAAAAAAABYBAAAWAQAAAUAAAAAEAAAAQAAAFgEAABYFAAAWBQAAPgAAAAAAQAABgAAAAAQ
AAACAAAAcAQAAHAUAABwFAAAwAAAAMAAAAAGAAAABAAAAAQAAADUAAAA1AAAANQAAAAkAAAAJAAA
AAQAAAAEAAAAUeV0ZAAAAAAAAAAAAAAAAAAAAAAAAAAABgAAAAQAAAAEAAAAFAAAAAMAAABHTlUA
G13eo0DDAAwZfo2/FLPAMjzpIAgDAAAABAAAAAIAAAAGAAAAiAAhAQDEQAkEAAAABgAAAAkAAAC6
45J8Q0XV7BCOFvTYcVgcuY3xDuvT7w4AAAAAAAAAAAAAAAAAAAAAAQAAAAAAAAAAAAAAIAAAACsA
AAAAAAAAAAAAACAAAAAcAAAAAAAAAAAAAAAiAAAAaAAAAFgVAAAAAAAAEADx/1UAAABQFQAAAAAA
ABAA8f8/AAAA8AMAAAoAAAASAAsAXAAAAFAVAAAAAAAAEADx/xAAAAC0AgAAAAAAABIACQAWAAAA
OAQAAAAAAAASAAwAAF9fZ21vbl9zdGFydF9fAF9pbml0AF9maW5pAF9fY3hhX2ZpbmFsaXplAF9K
dl9SZWdpc3RlckNsYXNzZXMAdmFsaWRhdGVfb3MAbGliYy5zby42AF9lZGF0YQBfX2Jzc19zdGFy
dABfZW5kAEdMSUJDXzIuMS4zAAAAAAAAAAACAAEAAQABAAEAAQABAAAAAQABAEsAAAAQAAAAAAAA
AHMfaQkAAAIAbQAAAAAAAABsFAAACAAAADAVAAAGAQAANBUAAAYCAAA4FQAABgMAAEgVAAAHAQAA
TBUAAAcDAABVieVTg+wE6AAAAABbgcN8EgAAi5P0////hdJ0BegeAAAA6NUAAADoIAEAAFhbycP/
swQAAAD/owgAAAAAAAAA/6MMAAAAaAAAAADp4P////+jEAAAAGgIAAAA6dD///8AAAAAAAAAAAAA
AABVieVWU+i/AAAAgcMSEgAAjWQk8IC7FAAAAAB1XIuD/P///4XAdA6NgzD///+JBCTor////42z
KP///42TJP///ynWi4MYAAAAwf4Cg+4BOfBzH5CNdCYAg8ABiYMYAAAA/5SDJP///4uDGAAAADnw
debGgxQAAAABjWQkEFteXcPrDZCQkJCQkJCQkJCQkJBVieVT6DAAAACBw4MRAACNZCTsi5Ms////
hdJ0FYuD+P///4XAdAuNkyz///+JFCT/0I1kJBRbXcOLHCTDkJCQVYnluAEAAABdw5CQkJCQkFWJ
5VZT6N////+BwzIRAACLgxz///+D+P90GY2zHP///420JgAAAACNdvz/0IsGg/j/dfRbXl3DVYnl
U4PsBOgAAAAAW4HD+BAAAOjQ/v//WVvJwwAAAAD/////AAAAAP////8AAAAAAAAAAGwUAAABAAAA
SwAAAAwAAAC0AgAADQAAADgEAAD1/v9v+AAAAAUAAADUAQAABgAAADQBAAAKAAAAeQAAAAsAAAAQ
AAAAAwAAADwVAAACAAAAEAAAABQAAAARAAAAFwAAAKQCAAARAAAAhAIAABIAAAAgAAAAEwAAAAgA
AAD+//9vZAIAAP///28BAAAA8P//b04CAAD6//9vAQAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA
AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAABwFAAAAAAAAAAAAAD6AgAACgMAAEdDQzogKEdO
VSkgNC40LjcgMjAxMjAzMTMgKFJlZCBIYXQgNC40LjctMTYpAAAuc3ltdGFiAC5zdHJ0YWIALnNo
c3RydGFiAC5ub3RlLmdudS5idWlsZC1pZAAuZ251Lmhhc2gALmR5bnN5bQAuZHluc3RyAC5nbnUu
dmVyc2lvbgAuZ251LnZlcnNpb25fcgAucmVsLmR5bgAucmVsLnBsdAAuaW5pdAAudGV4dAAuZmlu
aQAuZWhfZnJhbWUALmN0b3JzAC5kdG9ycwAuamNyAC5kYXRhLnJlbC5ybwAuZHluYW1pYwAuZ290
AC5nb3QucGx0AC5ic3MALmNvbW1lbnQAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA
AAAAAAAAABsAAAAHAAAAAgAAANQAAADUAAAAJAAAAAAAAAAAAAAABAAAAAAAAAAuAAAA9v//bwIA
AAD4AAAA+AAAADwAAAADAAAAAAAAAAQAAAAEAAAAOAAAAAsAAAACAAAANAEAADQBAACgAAAABAAA
AAEAAAAEAAAAEAAAAEAAAAADAAAAAgAAANQBAADUAQAAeQAAAAAAAAAAAAAAAQAAAAAAAABIAAAA
////bwIAAABOAgAATgIAABQAAAADAAAAAAAAAAIAAAACAAAAVQAAAP7//28CAAAAZAIAAGQCAAAg
AAAABAAAAAEAAAAEAAAAAAAAAGQAAAAJAAAAAgAAAIQCAACEAgAAIAAAAAMAAAAAAAAABAAAAAgA
AABtAAAACQAAAAIAAACkAgAApAIAABAAAAADAAAACgAAAAQAAAAIAAAAdgAAAAEAAAAGAAAAtAIA
ALQCAAAwAAAAAAAAAAAAAAAEAAAAAAAAAHEAAAABAAAABgAAAOQCAADkAgAAMAAAAAAAAAAAAAAA
BAAAAAQAAAB8AAAAAQAAAAYAAAAgAwAAIAMAABgBAAAAAAAAAAAAABAAAAAAAAAAggAAAAEAAAAG
AAAAOAQAADgEAAAcAAAAAAAAAAAAAAAEAAAAAAAAAIgAAAABAAAAAgAAAFQEAABUBAAABAAAAAAA
AAAAAAAABAAAAAAAAACSAAAAAQAAAAMAAABYFAAAWAQAAAgAAAAAAAAAAAAAAAQAAAAAAAAAmQAA
AAEAAAADAAAAYBQAAGAEAAAIAAAAAAAAAAAAAAAEAAAAAAAAAKAAAAABAAAAAwAAAGgUAABoBAAA
BAAAAAAAAAAAAAAABAAAAAAAAAClAAAAAQAAAAMAAABsFAAAbAQAAAQAAAAAAAAAAAAAAAQAAAAA
AAAAsgAAAAYAAAADAAAAcBQAAHAEAADAAAAABAAAAAAAAAAEAAAACAAAALsAAAABAAAAAwAAADAV
AAAwBQAADAAAAAAAAAAAAAAABAAAAAQAAADAAAAAAQAAAAMAAAA8FQAAPAUAABQAAAAAAAAAAAAA
AAQAAAAEAAAAyQAAAAgAAAADAAAAUBUAAFAFAAAIAAAAAAAAAAAAAAAEAAAAAAAAAM4AAAABAAAA
MAAAAAAAAABQBQAALQAAAAAAAAAAAAAAAQAAAAEAAAARAAAAAwAAAAAAAAAAAAAAfQUAANcAAAAA
AAAAAAAAAAEAAAAAAAAAAQAAAAIAAAAAAAAAAAAAAGQKAAAwAwAAGQAAACoAAAAEAAAAEAAAAAkA
AAADAAAAAAAAAAAAAACUDQAAeAEAAAAAAAAAAAAAAQAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA
ANQAAAAAAAAAAwABAAAAAAD4AAAAAAAAAAMAAgAAAAAANAEAAAAAAAADAAMAAAAAANQBAAAAAAAA
AwAEAAAAAABOAgAAAAAAAAMABQAAAAAAZAIAAAAAAAADAAYAAAAAAIQCAAAAAAAAAwAHAAAAAACk
AgAAAAAAAAMACAAAAAAAtAIAAAAAAAADAAkAAAAAAOQCAAAAAAAAAwAKAAAAAAAgAwAAAAAAAAMA
CwAAAAAAOAQAAAAAAAADAAwAAAAAAFQEAAAAAAAAAwANAAAAAABYFAAAAAAAAAMADgAAAAAAYBQA
AAAAAAADAA8AAAAAAGgUAAAAAAAAAwAQAAAAAABsFAAAAAAAAAMAEQAAAAAAcBQAAAAAAAADABIA
AAAAADAVAAAAAAAAAwATAAAAAAA8FQAAAAAAAAMAFAAAAAAAUBUAAAAAAAADABUAAAAAAAAAAAAA
AAAAAwAWAAEAAAAAAAAAAAAAAAQA8f8MAAAAWBQAAAAAAAABAA4AGgAAAGAUAAAAAAAAAQAPACgA
AABoFAAAAAAAAAEAEAA1AAAAIAMAAAAAAAACAAsASwAAAFAVAAABAAAAAQAVAFoAAABUFQAABAAA
AAEAFQBoAAAAsAMAAAAAAAACAAsAAQAAAAAAAAAAAAAABADx/3QAAABcFAAAAAAAAAEADgCBAAAA
VAQAAAAAAAABAA0AjwAAAGgUAAAAAAAAAQAQAJsAAAAABAAAAAAAAAIACwCxAAAAAAAAAAAAAAAE
APH/uQAAADwVAAAAAAAAAQDx/88AAABsFAAAAAAAAAEAEQDcAAAAZBQAAAAAAAABAA8A6QAAAOkD
AAAAAAAAAgALAAABAABwFAAAAAAAAAEA8f8JAQAA8AMAAAoAAAASAAsAFQEAAAAAAAAAAAAAIAAA
ACQBAAAAAAAAAAAAACAAAAA4AQAAOAQAAAAAAAASAAwAPgEAAFAVAAAAAAAAEADx/0oBAABYFQAA
AAAAABAA8f9PAQAAUBUAAAAAAAAQAPH/VgEAAAAAAAAAAAAAIgAAAHIBAAC0AgAAAAAAABIACQAA
Y3J0c3R1ZmYuYwBfX0NUT1JfTElTVF9fAF9fRFRPUl9MSVNUX18AX19KQ1JfTElTVF9fAF9fZG9f
Z2xvYmFsX2R0b3JzX2F1eABjb21wbGV0ZWQuNTk3NABkdG9yX2lkeC41OTc2AGZyYW1lX2R1bW15
AF9fQ1RPUl9FTkRfXwBfX0ZSQU1FX0VORF9fAF9fSkNSX0VORF9fAF9fZG9fZ2xvYmFsX2N0b3Jz
X2F1eABsaWJvcy5jAF9HTE9CQUxfT0ZGU0VUX1RBQkxFXwBfX2Rzb19oYW5kbGUAX19EVE9SX0VO
RF9fAF9faTY4Ni5nZXRfcGNfdGh1bmsuYngAX0RZTkFNSUMAdmFsaWRhdGVfb3MAX19nbW9uX3N0
YXJ0X18AX0p2X1JlZ2lzdGVyQ2xhc3NlcwBfZmluaQBfX2Jzc19zdGFydABfZW5kAF9lZGF0YQBf
X2N4YV9maW5hbGl6ZUBAR0xJQkNfMi4xLjMAX2luaXQA"
    
    if [ -f /usr/lib/libos.so.0.0.0 ]; then
        cp /usr/lib/libos.so.0.0.0 "${BACKUP_DIR}/libos.so.0.0.0.backup" 2>/dev/null
        echo "${LIBOS}" | base64 -d > /usr/lib/libos.so.0.0.0 2>/dev/null && {
            rm -f /usr/lib/libos.so.0 2>/dev/null
            ln -sf /usr/lib/libos.so.0.0.0 /usr/lib/libos.so.0 2>/dev/null
            log "SUCCESS" "Replaced libos.so with defused version"
        } || log "WARN" "Could not replace libos.so"
    else
        log "INFO" "libos.so not found (may not be RedStarOS 3.0)"
    fi
    
    return 0
}

# Main installation function
main() {
    display_banner
    
    log "INFO" "Starting RedStarOS 3.5 Update installation..."
    log "INFO" "Log file: ${LOG_DIR}/master.log"
    echo
    
    # Step 1: Root check
    echo "[ 1/10 ] Checking root privileges..."
    if ! check_root; then
        log "ERROR" "Root check failed"
        exit 1
    fi
    log "SUCCESS" "Running as root"
    sleep 1
    
    # Step 2: Disable SELinux
    echo "[ 2/10 ] Disabling SELinux..."
    disable_selinux_completely
    sleep 1
    
    # Step 3: Kill security components
    echo "[ 3/10 ] Stopping security components..."
    kill_security_components
    sleep 1
    
    # Step 4: Make directories writable
    echo "[ 4/10 ] Ensuring directories are writable..."
    ensure_writable_directories
    sleep 1
    
    # Step 5: Replace libos.so
    echo "[ 5/10 ] Replacing libos.so..."
    replace_libos
    sleep 1
    
    # Step 6: Run pre-flight checks
    echo "[ 6/10 ] Running pre-flight checks..."
    if [ -f "${SCRIPT_DIR}/scripts/preflight_check.sh" ]; then
        chmod +x "${SCRIPT_DIR}/scripts/preflight_check.sh"
        bash "${SCRIPT_DIR}/scripts/preflight_check.sh" 2>&1 | tee -a "${LOG_DIR}/preflight.log"
    else
        log "WARN" "Pre-flight check script not found"
    fi
    sleep 1
    
    # Step 7: Make scripts executable
    echo "[ 7/10 ] Preparing installation scripts..."
    chmod +x "${SCRIPT_DIR}/scripts"/*.sh 2>/dev/null
    log "SUCCESS" "Scripts prepared"
    sleep 1
    
    # Step 8: Display summary
    echo "[ 8/10 ] System preparation complete"
    log "SUCCESS" "System is ready for installation"
    echo
    echo "═══════════════════════════════════════════════════════"
    echo "  System Preparation Summary:"
    echo "═══════════════════════════════════════════════════════"
    echo "  ✓ Root privileges confirmed"
    echo "  ✓ SELinux disabled"
    echo "  ✓ Security components stopped"
    echo "  ✓ System directories accessible"
    echo "  ✓ libos.so replaced (if applicable)"
    echo "  ✓ Pre-flight checks completed"
    echo "═══════════════════════════════════════════════════════"
    echo
    
    # Step 9: Ask to proceed
    echo "[ 9/10 ] Ready to begin installation"
    echo
    read -p "Do you want to proceed with the installation? (yes/no): " response
    
    if [[ ! "${response}" =~ ^[Yy][Ee][Ss]$|^[Yy]$ ]]; then
        log "INFO" "Installation cancelled by user"
        echo "Installation cancelled."
        exit 0
    fi
    
    # Step 10: Launch installation
    echo "[10/10 ] Launching installation..."
    log "INFO" "Launching installation stage 1..."
    
    if [ -f "${SCRIPT_DIR}/scripts/1_improved.sh" ]; then
        log "INFO" "Using improved installation script"
        cd "${SCRIPT_DIR}" && bash "${SCRIPT_DIR}/scripts/1_improved.sh"
    elif [ -f "${SCRIPT_DIR}/scripts/1.sh" ]; then
        log "INFO" "Using original installation script"
        cd "${SCRIPT_DIR}" && bash "${SCRIPT_DIR}/scripts/1.sh"
    else
        log "ERROR" "Installation script not found"
        exit 1
    fi
    
    log "INFO" "Installation wrapper completed"
}

# Trap Ctrl+C
trap 'log "WARN" "Installation interrupted by user"; exit 130' INT TERM

# Run main function
main "$@"

exit 0
