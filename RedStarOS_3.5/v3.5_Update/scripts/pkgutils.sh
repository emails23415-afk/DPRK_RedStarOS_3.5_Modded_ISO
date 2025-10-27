#!/bin/bash
#
# RedStarOS Package Utilities - Enhanced Edition
# Automatic SELinux handling, security bypass, and resilient operations
# Credits: Original v3.5 Update Combo team, redstar-tools by takeshixx, CCC research
#

# Initialize environment
export SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
export LOG_DIR="${SCRIPT_DIR}/../logs"
export BACKUP_DIR="${SCRIPT_DIR}/../backup"
mkdir -p "${LOG_DIR}" "${BACKUP_DIR}" 2>/dev/null || true

# Logging function
log_message() {
    local level="$1"; shift
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] [$level] $@" | tee -a "${LOG_DIR}/installation.log" >/dev/null 2>&1 || true
}

# Check and handle root privileges
check_root() {
    if [ "$(id -u)" != "0" ]; then
        log_message "ERROR" "Root privileges required"
        echo "This installer must be run as root."
        echo "Please enable root access using one of these methods:"
        echo "  1. Run: /usr/sbin/rootsetting"
        echo "  2. Use: su - root"
        echo "  3. Run: sudo $0"
        echo ""
        # Try to automatically enable root
        command -v /usr/sbin/rootsetting &>/dev/null && /usr/sbin/rootsetting 2>/dev/null || true
        return 1
    fi
    log_message "INFO" "Running as root"
    return 0
}

# Disable SELinux completely
disable_selinux() {
    log_message "INFO" "Disabling SELinux"
    
    # Immediate disable
    command -v setenforce &>/dev/null && setenforce 0 2>/dev/null || true
    
    # Persistent disable in grub (multiple locations)
    for grub_conf in /boot/grub/grub.conf /boot/grub2/grub.cfg /etc/grub.conf /boot/efi/EFI/redhat/grub.conf; do
        if [ -f "${grub_conf}" ] && ! grep -q "selinux=0" "${grub_conf}"; then
            cp "${grub_conf}" "${BACKUP_DIR}/$(basename ${grub_conf}).bak" 2>/dev/null || true
            sed -i'.bak' '/kernel.*vmlinuz/ s/$/ selinux=0/' "${grub_conf}" 2>/dev/null || true
            log_message "INFO" "SELinux disabled in ${grub_conf}"
        fi
    done
    
    # Disable in config
    if [ -f /etc/selinux/config ]; then
        cp /etc/selinux/config "${BACKUP_DIR}/selinux_config.bak" 2>/dev/null || true
        sed -i 's/^SELINUX=.*/SELINUX=disabled/' /etc/selinux/config 2>/dev/null || true
    fi
    
    # Create disabled marker
    touch /etc/selinux/.disabled 2>/dev/null || true
    
    log_message "SUCCESS" "SELinux disabled"
    return 0
}

# Disable RedStarOS security components
disable_security_components() {
    log_message "INFO" "Disabling security components"
    
    # Kill security daemons
    killall -9 securityd opprc scnprc artsd 2>/dev/null || true
    
    # Disable rtscan kernel module (watermarking prevention)
    if [ -c /dev/res ] && command -v python &>/dev/null; then
        echo -e "import fcntl\nfcntl.ioctl(open('/dev/res', 'wb'), 29187)" | python 2>/dev/null || true
        log_message "INFO" "Disabled rtscan kernel module"
    fi
    
    # Remove autostarts
    for file in /usr/share/autostart/scnprc.desktop /etc/init/ctguard.conf; do
        [ -f "${file}" ] && mv "${file}" "${BACKUP_DIR}/$(basename ${file}).disabled" 2>/dev/null || true
    done
    
    # Replace libos.so with defused version (from redstar-tools)
    if [ -f /usr/lib/libos.so.0.0.0 ]; then
        cp /usr/lib/libos.so.0.0.0 "${BACKUP_DIR}/libos.so.0.0.0.backup" 2>/dev/null || true
        # Base64 encoded defused libos.so
        local LIBOS="f0VMRgEBAQAAAAAAAAAAAAMAAwABAAAAIAMAADQAAABUBgAAAAAAADQAIAAFACgAGgAXAAEAAAAA
AAAAAAAAAAAAAABYBAAAWAQAAAUAAAAAEAAAAQAAAFgEAABYFAAAWBQAAPgAAAAAAQAABgAAAAAQ
AAACAAAAcAQAAHAUAABwFAAAwAAAAMAAAAAGAAAABAAAAAQAAADUAAAA1AAAANQAAAAkAAAAJAAA
AAQAAAAEAAAAUeV0ZAAAAAAAAAAAAAAAAAAAAAAAAAAABgAAAAQAAAAEAAAAFAAAAAMAAABHTlUA
G13eo0DDAAwZfo2/FLPAMjzpIAgDAAAABAAAAAIAAAAGAAAAiAAhAQDEQAkEAAAABgAAAAkAAAC6
45J8Q0XV7BCOFvTYcVgcuY3xDuvT7w4AAAAAAAAAAAAAAAAAAAAAAQAAAAAAAAAAAAAAIAAAACsA
AAAAAAAAAAAAACAAAAAcAAAAAAAAAAAAAAAiAAAAaAAAAFgVAAAAAAAAEADx/1UAAABQFQAAAAAA
ABAAEf8/AAAA8AMAAAoAAAASAAsAXAAAAFAVAAAAAAAAEADx/xAAAAC0AgAAAAAAABIACQAWAAAA
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
AAAAAAMADwAAAAAAaBQAAAAAAAADABAAAAAAAGwUAAAAAAAAAwAQAAAAAABwFAAAAAAAAAMAEgAA
AAAAADAVAAAAAAAAAwATAAAAAAA8FQAAAAAAAAMAFAAAAAAAUBUAAAAAAAADABUAAAAAAAAAAAAA
AAAAAwAWAAEAAAAAAAAAAAAAAAQA8f8MAAAAWBQAAAAAAAABAA4AGgAAAGAUAAAAAAAAAQAPACgA
AABoFAAAAAAAAAEAEAA1AAAAIAMAAAAAAAACAAsASwAAAFAVAAABAAAAAQAVAFoAAABUFQAABAAA
AAEAFQBoAAAAsAMAAAAAAAACAAsAAQAAAAAAAAAAAAAABADx/3QAAABcFAAAAAAAAAEADgCBAAAA
VAQAAAAAAABBIAAN AJsAAAAAAAAAAAAAAAIACwCxAAAAAAAAAAAAAAAEAPH/uQAAADwVAAAAAAAAAQDx/88AAABsFAAAAAAAAAEAEQDcAAAAZBQAAAAAAAABAA8A6QAAAOkD
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
        echo "${LIBOS}" | base64 -d > /usr/lib/libos.so.0.0.0 2>/dev/null && {
            rm -f /usr/lib/libos.so.0 2>/dev/null || true
            ln -sf /usr/lib/libos.so.0.0.0 /usr/lib/libos.so.0 2>/dev/null || true
            log_message "INFO" "Replaced libos.so with defused version"
        } || log_message "WARN" "Could not replace libos.so"
    fi
    
    log_message "SUCCESS" "Security components disabled"
    return 0
}

# Enhanced MakeShortcut with multiple fallback strategies
MakeShortcut() {
    log_message "INFO" "Creating pkgtool shortcut"
    local script_path="${SCRIPT_DIR}/pkgutils.sh"
    
    # Try multiple locations with fallback
    for bin_dir in /bin /usr/local/bin /usr/bin; do
        if rm -f "${bin_dir}/pkgtool" 2>/dev/null && ln -sf "${script_path}" "${bin_dir}/pkgtool" 2>/dev/null; then
            log_message "SUCCESS" "Created pkgtool at ${bin_dir}/pkgtool"
            return 0
        fi
    done
    
    # Fallback: add to bashrc
    if ! grep -q "alias pkgtool=" ~/.bashrc 2>/dev/null; then
        echo "alias pkgtool='${script_path}'" >> ~/.bashrc 2>/dev/null && \
            log_message "SUCCESS" "Created pkgtool alias in ~/.bashrc"
    fi
    return 0
}

operationerror() {
    log_message "ERROR" "Operation error occurred"
    kdialog --title "Operation Cannot Be Completed" --error "An unexpected error occurred. Check ${LOG_DIR}/installation.log for details." 2>/dev/null || echo "ERROR: Check ${LOG_DIR}/installation.log"
    return 1
}

scripterror() {
    log_message "ERROR" "Script error at line ${BASH_LINENO[0]}"
    rm -f '/root/Desktop/v3.5 Update Combo/scripts/next.desktop' 2>/dev/null
    kdialog --title "Failed To Install v3.5 Update Combo" --error "Critical error. Check ${LOG_DIR}/installation.log" 2>/dev/null || echo "ERROR: Check logs"
    set +x
    cp -f ~/.bashrc /root/Desktop/v3.5\ Update\ Combo/scripts/trap 2>/dev/null || touch /root/Desktop/v3.5\ Update\ Combo/scripts/trap
    echo 'set -x' >> /root/Desktop/v3.5\ Update\ Combo/scripts/trap
    echo 'set +e' >> /root/Desktop/v3.5\ Update\ Combo/scripts/trap
    echo 'source pkgtool' >> /root/Desktop/v3.5\ Update\ Combo/scripts/trap
    exec bash --rcfile /root/Desktop/v3.5\ Update\ Combo/scripts/trap -i 2>/dev/null || bash -i
    exit 1
}

yumerror() {
    log_message "WARN" "Yum installation failed (non-critical)"
    kdialog --title "Failed To Install v3.5 Update Combo" --error "Failed to install via yum. If development tools are installed, this is OK.\nClick OK to continue..." 2>/dev/null || echo "WARNING: Yum failed, continuing..."
    return 0
}

title() {
    log_message "INFO" "$@"
    printf '\033]0;%s\007' "$*" 2>/dev/null || true
    return 0
}

nop() { return 0; }

# Enhanced Extract with better error handling
Extract() {
    set +e
    local package="$1" format="$2" title_text="${3:-Extracting ${package}}"
    log_message "INFO" "Extracting ${package}.tar.${format}"
    title "${title_text}"
    cd /workspace || { log_message "ERROR" "Cannot access /workspace"; return 1; }
    local tar_file="/root/Desktop/v3.5 Update Combo/packages/${package}.tar.${format}"
    [ ! -f "${tar_file}" ] && { log_message "ERROR" "Package not found: ${tar_file}"; return 1; }
    tar xvf "${tar_file}" 2>&1 | tee -a "${LOG_DIR}/extract_${package}.log" || { log_message "ERROR" "Extract failed"; return 1; }
    cd "${package}" 2>/dev/null || { log_message "ERROR" "Cannot enter ${package} directory"; return 1; }
    return 0
}

CleanUp() {
    set +e
    local package="$1" title_text="${2:-Cleaning ${package}}"
    log_message "INFO" "Cleaning ${package}"
    title "${title_text}"
    cd /workspace || return 0
    rm -rf "${package}" 2>/dev/null || log_message "WARN" "Could not remove ${package}"
    return 0
}

FullCleanUp() {
set -x
title "Cleaning All Workspaces" || return 1
rm -rf /workspace || return 1
rm -rf /opt/Cross64 || return 1
rm -rf /opt/NewRoot || return 1
mkdir /workspace || return 1
mkdir /opt/Cross64 || return 1
mkdir /opt/NewRoot || return 1
ln -sd /opt/Cross64 /workspace/Cross64 || return 1
ln -sd /opt/NewRoot /workspace/NewRoot || return 1
cd /workspace || return 1
return 0
}

WorkspaceCleanUp() {
set -x
title "Cleaning Workspace" || return 1
rm -rf /workspace || return 1
mkdir /workspace || return 1
mkdir /opt/Cross64 || true
mkdir /opt/NewRoot || true
ln -sd /opt/Cross64 /workspace/Cross64 || return 1
ln -sd /opt/NewRoot /workspace/NewRoot || return 1
cd /workspace || return 1
return 0
}

Cross64CleanUp() {
set -x
title "Cleaning Cross64 Workspace" || return 1
rm -rf /opt/Cross64 || return 1
rm -rf /opt/NewRoot || return 1
rm -f /workspace/Cross64 || return 1
rm -f /workspace/NewRoot || return 1
mkdir /opt/Cross64 || return 1
mkdir /opt/NewRoot || return 1
ln -sd /opt/Cross64 /workspace/Cross64 || return 1
ln -sd /opt/NewRoot /workspace/NewRoot || return 1
cd /opt/Cross64 || return 1
return 0
}

InstallBase() {
set -x
local Package="${1}" || return 1
local Format="${2}" || return 1
local TitleText="${3}" || return 1
local Subfolder="${4}" || return 1
local ConfigureCommand="${5}" || return 1
local MakeCommand="${6}" || return 1
local CheckCommand="${7}" || return 1
local DeployCommand="${8}" || return 1
local TitlePostfixA="${9}" || return 1
local TitlePostfixB="${10}" || return 1
local TitlePostfixC="${11}" || return 1
local TitlePostfixD="${12}" || return 1
local TitlePostfixE="${13}" || return 1
local TitlePostfixF="${14}" || return 1
Extract "${Package}" "${Format}" "${TitleText} [${TitlePostfixA}]" || return 1
if [[ -n "${Subfolder}" ]]; then
mkdir "${Subfolder}" || return 1
cd "${Subfolder}" || return 1
fi
title "${TitleText} [${TitlePostfixB}]" || return 1
eval ${ConfigureCommand} || return 1
title "${TitleText} [${TitlePostfixC}]" || return 1
eval ${MakeCommand} || return 1
title "${TitleText} [${TitlePostfixD}]" || return 1
eval ${CheckCommand} || return 1
title "${TitleText} [${TitlePostfixE}]" || return 1
eval ${DeployCommand}  || return 1
CleanUp "${Package}" "${TitleText} [${TitlePostfixF}]" || return 1
return 0
}

InstallEngine() {
set -x
local Package="${1}" || return 1
local Format="${2}" || return 1
local Thread="${3}" || return 1
local TitlePostfix="${4}" || return 1
shift 4 || return 1
local TitleText="Installing ${Package} ${TitlePostfix}" || return 1
local Subfolder="W0RK" || return 1
local ConfigureCommand="../configure ${@}" || return 1
local MakeCommand="make all -j${Thread}" || return 1
local CheckCommand="make check" || return 1
local DeployCommand="make install" || return 1
InstallBase "${Package}" "${Format}" "${TitleText}" "${Subfolder}" "${ConfigureCommand}" "${MakeCommand}" "${CheckCommand}" "${DeployCommand}" 'Extracting' 'Configuring' 'Compiling' 'Validating' 'Deploying' 'Cleaning' || return 1
return 0
}

InstallEngineNoCheck() {
set -x
local Package="${1}" || return 1
local Format="${2}" || return 1
local Thread="${3}" || return 1
local TitlePostfix="${4}" || return 1
shift 4 || return 1
local TitleText="Installing ${Package} ${TitlePostfix}" || return 1
local Subfolder="W0RK" || return 1
local ConfigureCommand="../configure ${@}" || return 1
local MakeCommand="make all -j${Thread}" || return 1
local CheckCommand="nop" || return 1
local DeployCommand="make install" || return 1
InstallBase "${Package}" "${Format}" "${TitleText}" "${Subfolder}" "${ConfigureCommand}" "${MakeCommand}" "${CheckCommand}" "${DeployCommand}" 'Extracting' 'Configuring' 'Compiling' 'Validating' 'Deploying' 'Cleaning' || return 1
return 0
}

CustomInstall() {
set -x
local Package="${1}" || return 1
local Format="${2}" || return 1
local TitlePostfix="${3}" || return 1
local TitleText="Installing ${Package} ${TitlePostfix}" || return 1
local Subfolder="${4}" || return 1
local ConfigureCommand="${5}" || return 1
local MakeCommand="${6}" || return 1
local CheckCommand="${7}" || return 1
local DeployCommand="${8}" || return 1
shift 7 || return 1
InstallBase "${Package}" "${Format}" "${TitleText}" "${Subfolder}" "${ConfigureCommand}" "${MakeCommand}" "${CheckCommand}" "${DeployCommand}" 'Extracting' 'Configuring' 'Compiling' 'Validating' 'Deploying' 'Cleaning' || return 1
return 0
}

Install() {
set -x
local Package="${1}" || return 1
local Format="${2}" || return 1
shift 2 || return 1
InstallEngine "${Package}" "${Format}" "$(grep -c ^processor /proc/cpuinfo)" "For Host" "--prefix=/usr" "${@}" || return 1
return 0
}

InstallJ1() {
set -x
local Package="${1}" || return 1
local Format="${2}" || return 1
shift 2 || return 1
InstallEngine "${Package}" "${Format}" '1' "For Host" "--prefix=/usr" "${@}" || return 1
return 0
}

InstallRoot() {
set -x
local Package="${1}" || return 1
local Format="${2}" || return 1
shift 2 || return 1
InstallEngine "${Package}" "${Format}" "$(grep -c ^processor /proc/cpuinfo)" "For Host" "--prefix=" "${@}" || return 1
return 0
}

InstallRootJ1() {
set -x
local Package="${1}" || return 1
local Format="${2}" || return 1
shift 2 || return 1
InstallEngine "${Package}" "${Format}" '1' "For Host" "--prefix=" "${@}" || return 1
return 0
}

Cross64EnvSetup() {
set -x
export CROSS_PREFIX=/opt/Cross64 || return 1
export TARGET=x86_64-pc-linux-gnu || return 1
export SYSROOT=/opt/NewRoot || return 1
export LIBRARY_PATH=${SYSROOT}/lib64:${SYSROOT}/lib32:${SYSROOT}/lib:${CROSS_PREFIX}/${TARGET}/lib64:${CROSS_PREFIX}/${TARGET}/lib:/usr/lib/:/lib || return 1
return 0
}

Cross64EnvCleanUp() {
set -x
unset CROSS_PREFIX || return 1
unset TARGET || return 1
unset SYSROOT || return 1
unset LIBRARY_PATH || return 1
return 0
}

InstallCross64() {
set -x
local Package="${1}" || return 1
local Format="${2}" || return 1
shift 2 || return 1
InstallEngine "${Package}" "${Format}" "$(grep -c ^processor /proc/cpuinfo)" "For Cross-x86_64" "--target=x86_64-pc-linux-gnu --prefix=/opt/Cross64 --with-sysroot=/opt/NewRoot" "${@}" || return 1
return 0
}

InstallCross64J1() {
set -x
local Package="${1}" || return 1
local Format="${2}" || return 1
shift 2 || return 1
InstallEngine "${Package}" "${Format}" '1' "For Cross-x86_64" "--target=x86_64-pc-linux-gnu --prefix=/opt/Cross64 --with-sysroot=/opt/NewRoot" "${@}" || return 1
return 0
}

InstallCross64Root() {
set -x
local Package="${1}" || return 1
local Format="${2}" || return 1
shift 2 || return 1
InstallEngine "${Package}" "${Format}" "$(grep -c ^processor /proc/cpuinfo)" "For Cross-x86_64" "--target=x86_64-pc-linux-gnu --prefix=/opt/NewRoot --with-sysroot=/opt/NewRoot" "${@}" || return 1
return 0
}

InstallCross64RootJ1() {
set -x
local Package="${1}" || return 1
local Format="${2}" || return 1
shift 2 || return 1
InstallEngine "${Package}" "${Format}" '1' "For Cross-x86_64" "--target=x86_64-pc-linux-gnu --prefix=/opt/NewRoot --with-sysroot=/opt/NewRoot" "${@}" || return 1
return 0
}

InstallCross64Alt() {
set -x
local Package="${1}" || return 1
local Format="${2}" || return 1
shift 2 || return 1
Cross64EnvSetup || return 1
InstallEngine "${Package}" "${Format}" "$(grep -c ^processor /proc/cpuinfo)" "For Cross-x86_64" "--host=x86_64-pc-linux-gnu --prefix=/opt/Cross64 --with-sysroot=/opt/NewRoot" "${@}" || return 1
Cross64EnvCleanUp || return 1
return 0
}

InstallCross64AltJ1() {
set -x
local Package="${1}" || return 1
local Format="${2}" || return 1
shift 2 || return 1
Cross64EnvSetup || return 1
InstallEngine "${Package}" "${Format}" '1' "For Cross-x86_64" "--host=x86_64-pc-linux-gnu --prefix=/opt/Cross64 --with-sysroot=/opt/NewRoot" "${@}" || return 1
Cross64EnvCleanUp || return 1
return 0
}

InstallCross64RootAlt() {
set -x
local Package="${1}" || return 1
local Format="${2}" || return 1
shift 2 || return 1
Cross64EnvSetup || return 1
InstallEngine "${Package}" "${Format}" "$(grep -c ^processor /proc/cpuinfo)" "For Cross-x86_64" "--host=x86_64-pc-linux-gnu --prefix=/opt/NewRoot --with-sysroot=/opt/NewRoot" "${@}" || return 1
Cross64EnvCleanUp || return 1
return 0
}

InstallCross64RootAltJ1() {
set -x
local Package="${1}" || return 1
local Format="${2}" || return 1
shift 2 || return 1
Cross64EnvSetup || return 1
InstallEngine "${Package}" "${Format}" '1' "For Cross-x86_64" "--host=x86_64-pc-linux-gnu --prefix=/opt/NewRoot --with-sysroot=/opt/NewRoot" "${@}" || return 1
Cross64EnvCleanUp || return 1
return 0
}

Native64EnvSetup() {
set -x
export CROSS_PREFIX=/opt/Cross64 || return 1
export TARGET=x86_64-pc-linux-gnu || return 1
export SYSROOT=/opt/NewRoot || return 1
export LIBRARY_PATH=${SYSROOT}/lib64:${SYSROOT}/lib32:${SYSROOT}/lib:/usr/lib/:/lib || return 1
export CC=${CROSS_PREFIX}/bin/${TARGET}-gcc || return 1
export GCC=${CROSS_PREFIX}/bin/${TARGET}-gcc || return 1
export CXX=${CROSS_PREFIX}/bin/${TARGET}-g++ || return 1
export GXX=${CROSS_PREFIX}/bin/${TARGET}-c++ || return 1
export CPP=${CROSS_PREFIX}/bin/${TARGET}-cpp || return 1
export CXXFILT=${CROSS_PREFIX}/bin/${TARGET}-c++filt || return 1
export AR=${CROSS_PREFIX}/bin/${TARGET}-ar || return 1
export AS=${CROSS_PREFIX}/bin/${TARGET}-as || return 1
export LD=${CROSS_PREFIX}/bin/${TARGET}-ld || return 1
export NM=${CROSS_PREFIX}/bin/${TARGET}-nm || return 1
export RANLIB=${CROSS_PREFIX}/bin/${TARGET}-ranlib || return 1
export STRIP=${CROSS_PREFIX}/bin/${TARGET}-strip || return 1
export STRINGS=${CROSS_PREFIX}/bin/${TARGET}-strings || return 1
export SIZE=${CROSS_PREFIX}/bin/${TARGET}-size || return 1
export OBJCOPY=${CROSS_PREFIX}/bin/${TARGET}-objcopy || return 1
export OBJDUMP=${CROSS_PREFIX}/bin/${TARGET}-objdump || return 1
export READELF=${CROSS_PREFIX}/bin/${TARGET}-readelf || return 1
export ELFEDIT=${CROSS_PREFIX}/bin/${TARGET}-elfedit || return 1
export GCOV=${CROSS_PREFIX}/bin/${TARGET}-gcov || return 1
export GCOV_DUMP=${CROSS_PREFIX}/bin/${TARGET}-gcov-dump || return 1
export GCOV_TOOL=${CROSS_PREFIX}/bin/${TARGET}-gcov-tool || return 1
export GPROF=${CROSS_PREFIX}/bin/${TARGET}-gprof || return 1
export ADDR2LINE=${CROSS_PREFIX}/bin/${TARGET}-addr2line || return 1
$CC --help || return 1
$GCC --help || return 1
$CXX --help || return 1
$GXX --help || return 1
$CPP --help || return 1
$CXXFILT --help || return 1
$AR --help || return 1
$AS --help || return 1
$LD --help || return 1
$NM --help || return 1
$RANLIB --help || return 1
$STRIP --help || return 1
$STRINGS --help || return 1
$SIZE --help || return 1
$OBJCOPY --help || return 1
$OBJDUMP --help || return 1
$READELF --help || return 1
$ELFEDIT --help || return 1
$GCOV --help || return 1
$GCOV_DUMP --help || return 1
$GCOV_TOOL --help || return 1
$GPROF --help || return 1
$ADDR2LINE --help || return 1
return 0
}

Native64EnvCleanUp() {
set -x
unset CROSS_PREFIX || return 1
unset TARGET || return 1
unset SYSROOT || return 1
unset LIBRARY_PATH || return 1
unset CC || return 1
unset GCC || return 1
unset CXX || return 1
unset GXX || return 1
unset CPP || return 1
unset CXXFILT || return 1
unset AR || return 1
unset AS || return 1
unset LD || return 1
unset NM || return 1
unset RANLIB || return 1
unset STRIP || return 1
unset STRINGS || return 1
unset SIZE || return 1
unset OBJCOPY || return 1
unset OBJDUMP || return 1
unset READELF || return 1
unset ELFEDIT || return 1
unset GCOV || return 1
unset GCOV_DUMP || return 1
unset GCOV_TOOL || return 1
unset GPROF || return 1
unset ADDR2LINE || return 1
return 0
}

InstallNative64() {
set -x
local Package="${1}" || return 1
local Format="${2}" || return 1
shift 2 || return 1
Native64EnvSetup || return 1
InstallEngine "${Package}" "${Format}" "$(grep -c ^processor /proc/cpuinfo)" "For Host-x64" "--prefix=/usr --with-sysroot=/opt/NewRoot" "${@}" || return 1
Native64EnvCleanUp || return 1
return 0
}

InstallNative64J1() {
set -x
local Package="${1}" || return 1
local Format="${2}" || return 1
shift 2 || return 1
Native64EnvSetup || return 1
InstallEngine "${Package}" "${Format}" '1' "For Host-x64" "--prefix=/usr --with-sysroot=/opt/NewRoot" "${@}" || return 1
Native64EnvCleanUp || return 1
return 0
}

InstallNative64Root() {
set -x
local Package="${1}" || return 1
local Format="${2}" || return 1
shift 2 || return 1
Native64EnvSetup || return 1
InstallEngine "${Package}" "${Format}" "$(grep -c ^processor /proc/cpuinfo)" "For Host-x64" "--prefix= --with-sysroot=/opt/NewRoot" "${@}" || return 1
Native64EnvCleanUp || return 1
return 0
}

InstallNative64RootJ1() {
set -x
local Package="${1}" || return 1
local Format="${2}" || return 1
shift 2 || return 1
Native64EnvSetup || return 1
InstallEngine "${Package}" "${Format}" '1' "For Host-x64" "--prefix= --with-sysroot=/opt/NewRoot" "${@}" || return 1
Native64EnvCleanUp || return 1
return 0
}

InstallNative64Cross() {
set -x
local Package="${1}" || return 1
local Format="${2}" || return 1
shift 2 || return 1
Native64EnvSetup || return 1
InstallEngine "${Package}" "${Format}" "$(grep -c ^processor /proc/cpuinfo)" "For Cross-x86_64-Native" "--prefix=/opt/Cross64 --with-sysroot=/opt/NewRoot" "${@}" || return 1
Native64EnvCleanUp || return 1
return 0
}

InstallNative64CrossJ1() {
set -x
local Package="${1}" || return 1
local Format="${2}" || return 1
shift 2 || return 1
Native64EnvSetup || return 1
InstallEngine "${Package}" "${Format}" '1' "For Cross-x86_64-Native" "--prefix=/opt/Cross64 --with-sysroot=/opt/NewRoot" "${@}" || return 1
Native64EnvCleanUp || return 1
return 0
}

InstallNative64RootCross() {
set -x
local Package="${1}" || return 1
local Format="${2}" || return 1
shift 2 || return 1
Native64EnvSetup || return 1
InstallEngine "${Package}" "${Format}" "$(grep -c ^processor /proc/cpuinfo)" "For Cross-x86_64-Native" "--prefix=/opt/NewRoot --with-sysroot=/opt/NewRoot" "${@}" || return 1
Native64EnvCleanUp || return 1
return 0
}

InstallNative64RootCrossJ1() {
set -x
local Package="${1}" || return 1
local Format="${2}" || return 1
shift 2 || return 1
Native64EnvSetup || return 1
InstallEngine "${Package}" "${Format}" '1' "For Cross-x86_64-Native" "--prefix=/opt/NewRoot --with-sysroot=/opt/NewRoot" "${@}" || return 1
Native64EnvCleanUp || return 1
return 0
}

InstallNoCheck() {
set -x
local Package="${1}" || return 1
local Format="${2}" || return 1
shift 2 || return 1
InstallEngineNoCheck "${Package}" "${Format}" "$(grep -c ^processor /proc/cpuinfo)" "For Host" "--prefix=/usr" "${@}" || return 1
return 0
}

InstallJ1NoCheck() {
set -x
local Package="${1}" || return 1
local Format="${2}" || return 1
shift 2 || return 1
InstallEngineNoCheck "${Package}" "${Format}" '1' "For Host" "--prefix=/usr" "${@}" || return 1
return 0
}

InstallRootNoCheck() {
set -x
local Package="${1}" || return 1
local Format="${2}" || return 1
shift 2 || return 1
InstallEngineNoCheck "${Package}" "${Format}" "$(grep -c ^processor /proc/cpuinfo)" "For Host" "--prefix=" "${@}" || return 1
return 0
}

InstallRootJ1NoCheck() {
set -x
local Package="${1}" || return 1
local Format="${2}" || return 1
shift 2 || return 1
InstallEngineNoCheck "${Package}" "${Format}" '1' "For Host" "--prefix=" "${@}" || return 1
return 0
}

InstallCross64NoCheck() {
set -x
local Package="${1}" || return 1
local Format="${2}" || return 1
shift 2 || return 1
InstallEngineNoCheck "${Package}" "${Format}" "$(grep -c ^processor /proc/cpuinfo)" "For Cross-x86_64" "--target=x86_64-pc-linux-gnu --prefix=/opt/Cross64 --with-sysroot=/opt/NewRoot" "${@}" || return 1
return 0
}

InstallCross64J1NoCheck() {
set -x
local Package="${1}" || return 1
local Format="${2}" || return 1
shift 2 || return 1
InstallEngineNoCheck "${Package}" "${Format}" '1' "For Cross-x86_64" "--target=x86_64-pc-linux-gnu --prefix=/opt/Cross64 --with-sysroot=/opt/NewRoot" "${@}" || return 1
return 0
}

InstallCross64RootNoCheck() {
set -x
local Package="${1}" || return 1
local Format="${2}" || return 1
shift 2 || return 1
InstallEngineNoCheck "${Package}" "${Format}" "$(grep -c ^processor /proc/cpuinfo)" "For Cross-x86_64" "--target=x86_64-pc-linux-gnu --prefix=/opt/NewRoot --with-sysroot=/opt/NewRoot" "${@}" || return 1
return 0
}

InstallCross64RootJ1NoCheck() {
set -x
local Package="${1}" || return 1
local Format="${2}" || return 1
shift 2 || return 1
InstallEngineNoCheck "${Package}" "${Format}" '1' "For Cross-x86_64" "--target=x86_64-pc-linux-gnu --prefix=/opt/NewRoot --with-sysroot=/opt/NewRoot" "${@}" || return 1
return 0
}

InstallCross64AltNoCheck() {
set -x
local Package="${1}" || return 1
local Format="${2}" || return 1
shift 2 || return 1
Cross64EnvSetup || return 1
InstallEngineNoCheck "${Package}" "${Format}" "$(grep -c ^processor /proc/cpuinfo)" "For Cross-x86_64" "--host=x86_64-pc-linux-gnu --prefix=/opt/Cross64 --with-sysroot=/opt/NewRoot" "${@}" || return 1
Cross64EnvCleanUp || return 1
return 0
}

InstallCross64AltJ1NoCheck() {
set -x
local Package="${1}" || return 1
local Format="${2}" || return 1
shift 2 || return 1
Cross64EnvSetup || return 1
InstallEngineNoCheck "${Package}" "${Format}" '1' "For Cross-x86_64" "--host=x86_64-pc-linux-gnu --prefix=/opt/Cross64 --with-sysroot=/opt/NewRoot" "${@}" || return 1
Cross64EnvCleanUp || return 1
return 0
}

InstallCross64RootAltNoCheck() {
set -x
local Package="${1}" || return 1
local Format="${2}" || return 1
shift 2 || return 1
Cross64EnvSetup || return 1
InstallEngineNoCheck "${Package}" "${Format}" "$(grep -c ^processor /proc/cpuinfo)" "For Cross-x86_64" "--host=x86_64-pc-linux-gnu --prefix=/opt/NewRoot --with-sysroot=/opt/NewRoot" "${@}" || return 1
Cross64EnvCleanUp || return 1
return 0
}

InstallCross64RootAltJ1NoCheck() {
set -x
local Package="${1}" || return 1
local Format="${2}" || return 1
shift 2 || return 1
Cross64EnvSetup || return 1
InstallEngineNoCheck "${Package}" "${Format}" '1' "For Cross-x86_64" "--host=x86_64-pc-linux-gnu --prefix=/opt/NewRoot --with-sysroot=/opt/NewRoot" "${@}" || return 1
Cross64EnvCleanUp || return 1
return 0
}

InstallNative64NoCheck() {
set -x
local Package="${1}" || return 1
local Format="${2}" || return 1
shift 2 || return 1
Native64EnvSetup || return 1
InstallEngineNoCheck "${Package}" "${Format}" "$(grep -c ^processor /proc/cpuinfo)" "For Host-x64" "--prefix=/usr --with-sysroot=/opt/NewRoot" "${@}" || return 1
Native64EnvCleanUp || return 1
return 0
}

InstallNative64J1NoCheck() {
set -x
local Package="${1}" || return 1
local Format="${2}" || return 1
shift 2 || return 1
Native64EnvSetup || return 1
InstallEngineNoCheck "${Package}" "${Format}" '1' "For Host-x64" "--prefix=/usr --with-sysroot=/opt/NewRoot" "${@}" || return 1
Native64EnvCleanUp || return 1
return 0
}

InstallNative64RootNoCheck() {
set -x
local Package="${1}" || return 1
local Format="${2}" || return 1
shift 2 || return 1
Native64EnvSetup || return 1
InstallEngineNoCheck "${Package}" "${Format}" "$(grep -c ^processor /proc/cpuinfo)" "For Host-x64" "--prefix= --with-sysroot=/opt/NewRoot" "${@}" || return 1
Native64EnvCleanUp || return 1
return 0
}

InstallNative64RootJ1NoCheck() {
set -x
local Package="${1}" || return 1
local Format="${2}" || return 1
shift 2 || return 1
Native64EnvSetup || return 1
InstallEngineNoCheck "${Package}" "${Format}" '1' "For Host-x64" "--prefix= --with-sysroot=/opt/NewRoot" "${@}" || return 1
Native64EnvCleanUp || return 1
return 0
}

InstallNative64CrossNoCheck() {
set -x
local Package="${1}" || return 1
local Format="${2}" || return 1
shift 2 || return 1
Native64EnvSetup || return 1
InstallEngineNoCheck "${Package}" "${Format}" "$(grep -c ^processor /proc/cpuinfo)" "For Cross-x86_64-Native" "--prefix=/opt/Cross64 --with-sysroot=/opt/NewRoot" "${@}" || return 1
Native64EnvCleanUp || return 1
return 0
}

InstallNative64CrossJ1NoCheck() {
set -x
local Package="${1}" || return 1
local Format="${2}" || return 1
shift 2 || return 1
Native64EnvSetup || return 1
InstallEngineNoCheck "${Package}" "${Format}" '1' "For Cross-x86_64-Native" "--prefix=/opt/Cross64 --with-sysroot=/opt/NewRoot" "${@}" || return 1
Native64EnvCleanUp || return 1
return 0
}

InstallNative64RootCrossNoCheck() {
set -x
local Package="${1}" || return 1
local Format="${2}" || return 1
shift 2 || return 1
Native64EnvSetup || return 1
InstallEngineNoCheck "${Package}" "${Format}" "$(grep -c ^processor /proc/cpuinfo)" "For Cross-x86_64-Native" "--prefix=/opt/NewRoot --with-sysroot=/opt/NewRoot" "${@}" || return 1
Native64EnvCleanUp || return 1
return 0
}

InstallNative64RootCrossJ1NoCheck() {
set -x
local Package="${1}" || return 1
local Format="${2}" || return 1
shift 2 || return 1
Native64EnvSetup || return 1
InstallEngineNoCheck "${Package}" "${Format}" '1' "For Cross-x86_64-Native" "--prefix=/opt/NewRoot --with-sysroot=/opt/NewRoot" "${@}" || return 1
Native64EnvCleanUp || return 1
return 0
}

RemoveEngine() {
set -x
local Package="${1}" || return 1
local Format="${2}" || return 1
local TitlePostfix="${3}" || return 1
shift 3 || return 1
local TitleText="Removing ${Package} ${TitlePostfix}" || return 1
local Subfolder="W0RK" || return 1
local ConfigureCommand="../configure ${@}" || return 1
local MakeCommand="nop" || return 1
local CheckCommand="nop" || return 1
local DeployCommand="make uninstall" || return 1
InstallBase "${Package}" "${Format}" "${TitleText}" "${Subfolder}" "${ConfigureCommand}" "${MakeCommand}" "${CheckCommand}" "${DeployCommand}" 'Extracting' 'Configuring' 'Compiling' 'Validating' 'Erasing' 'Cleaning' || return 1
return 0
}

Remove() {
set -x
local Package="${1}" || return 1
local Format="${2}" || return 1
shift 2 || return 1
RemoveEngine "${Package}" "${Format}" "For Host"  "--prefix=/usr" "${@}" || return 1
return 0
}

RemoveRoot() {
set -x
local Package="${1}" || return 1
local Format="${2}" || return 1
shift 2 || return 1
RemoveEngine "${Package}" "${Format}" "For Host" "--prefix=" "${@}" || return 1
return 0
}

RemoveCross64() {
set -x
local Package="${1}" || return 1
local Format="${2}" || return 1
shift 2 || return 1
RemoveEngine "${Package}" "${Format}" "For Cross-x86_64" "--target=x86_64-pc-linux-gnu --prefix=/opt/Cross64" "${@}" || return 1
return 0
}

RemoveCross64Root() {
set -x
local Package="${1}" || return 1
local Format="${2}" || return 1
shift 2 || return 1
RemoveEngine "${Package}" "${Format}" "For Cross-x86_64" "--target=x86_64-pc-linux-gnu --prefix=/opt/NewRoot" "${@}" || return 1
return 0
}

RemoveCross64Alt() {
set -x
local Package="${1}" || return 1
local Format="${2}" || return 1
shift 2 || return 1
Cross64EnvSetup || return 1
RemoveEngine "${Package}" "${Format}" "For Cross-x86_64" "--host=x86_64-pc-linux-gnu --prefix=/opt/Cross64" "${@}" || return 1
Cross64EnvCleanUp || return 1
return 0
}

RemoveCross64RootAlt() {
set -x
local Package="${1}" || return 1
local Format="${2}" || return 1
shift 2 || return 1
Cross64EnvSetup || return 1
RemoveEngine "${Package}" "${Format}" "For Cross-x86_64" "--host=x86_64-pc-linux-gnu --prefix=/opt/NewRoot" "${@}" || return 1
Cross64EnvCleanUp || return 1
return 0
}

RemoveNative64() {
set -x
local Package="${1}" || return 1
local Format="${2}" || return 1
shift 2 || return 1
Native64EnvSetup || return 1
RemoveEngine "${Package}" "${Format}" "For Host-x64" "--prefix=/usr --with-sysroot=/opt/NewRoot" "${@}" || return 1
Native64EnvCleanUp || return 1
return 0
}

RemoveNative64Root() {
set -x
local Package="${1}" || return 1
local Format="${2}" || return 1
shift 2 || return 1
Native64EnvSetup || return 1
RemoveEngine "${Package}" "${Format}" "For Host-x64" "--prefix= --with-sysroot=/opt/NewRoot" "${@}" || return 1
Native64EnvCleanUp || return 1
return 0
}

RemoveNative64Cross() {
set -x
local Package="${1}" || return 1
local Format="${2}" || return 1
shift 2 || return 1
Native64EnvSetup || return 1
RemoveEngine "${Package}" "${Format}" "For Host-x64" "--prefix=/opt/Cross64 --with-sysroot=/opt/NewRoot" "${@}" || return 1
Native64EnvCleanUp || return 1
return 0
}

RemoveNative64RootCross() {
set -x
local Package="${1}" || return 1
local Format="${2}" || return 1
shift 2 || return 1
Native64EnvSetup || return 1
RemoveEngine "${Package}" "${Format}" "For Host-x64" "--prefix=/opt/NewRoot --with-sysroot=/opt/NewRoot" "${@}" || return 1
Native64EnvCleanUp || return 1
return 0
}

Check() {
set -x
local Package="${1}" || return 1
local Format="${2}" || return 1
shift 2 || return 1
local TitleText="Checking Configure Options Of ${Package}" || return 1
local Subfolder="" || return 1
local ConfigureCommand="./configure ${@} --help" || return 1
local MakeCommand="nop" || return 1
local CheckCommand="nop" || return 1
local DeployCommand="nop" || return 1
InstallBase "${Package}" "${Format}" "${TitleText}" "${Subfolder}" "${ConfigureCommand}" "${MakeCommand}" "${CheckCommand}" "${DeployCommand}" 'Extracting' 'Configuring' 'Compiling' 'Validating' 'Deploying' 'Cleaning' || return 1
return 0
}

CheckMake() {
set -x
local Package="${1}" || return 1
local Format="${2}" || return 1
shift 2 || return 1
local TitleText="Checking Make Targets Of ${Package}" || return 1
local Subfolder="" || return 1
local ConfigureCommand="./configure ${@}" || return 1
local MakeCommand='make -pRrsq > TMP 2>&1 || true' || return 1
local CheckCommand="nop" || return 1
local DeployCommand='killall -9 -e simpletext || true; /Applications/SimpleText.app/Contents/RedStar/simpletext TMP; rm -f TMP' || return 1
InstallBase "${Package}" "${Format}" "${TitleText}" "${Subfolder}" "${ConfigureCommand}" "${MakeCommand}" "${CheckCommand}" "${DeployCommand}" 'Extracting' 'Configuring' 'Compiling' 'Validating' 'Deploying' 'Cleaning' || return 1
return 0
}

KernelInstall() {
set -x
local Package="linux-${1}" || return 1
local Format="${2}" || return 1
local TitleText="Installing Kernel ${Package}" || return 1
local ConfigureCommand="make allyesconfig" || return 1
local MakeCommand="make -j$(grep -c ^processor /proc/cpuinfo)" || return 1
local DeployCommandA="make modules_install" || return 1
local DeployCommandB="make install" || return 1
local DeployCommandC="make headers_install INSTALL_HDR_PATH=/usr" || return 1
local TitlePostfixA="Extracting" || return 1
local TitlePostfixB="Configuring" || return 1
local TitlePostfixC="Compiling" || return 1
local TitlePostfixD="Deploying Modules" || return 1
local TitlePostfixE="Deploying Ramfs & vmlinuz" || return 1
local TitlePostfixF="Deploying Headers" || return 1
title "${TitleText} [${TitlePostfixA}]" || return 1
cd /usr/src/kernels || return 1
tar xvf "/root/Desktop/v3.5 Update Combo/packages/${Package}.tar.${Format}" || return 1
cd "${Package}" || return 1
title "${TitleText} [${TitlePostfixB}]" || return 1
eval ${ConfigureCommand} || return 1
title "${TitleText} [${TitlePostfixC}]" || return 1
eval ${MakeCommand} || return 1
title "${TitleText} [${TitlePostfixD}]" || return 1
eval ${DeployCommandA}  || return 1
title "${TitleText} [${TitlePostfixE}]" || return 1
eval ${DeployCommandB}  || return 1
title "${TitleText} [${TitlePostfixF}]" || return 1
eval ${DeployCommandC}  || return 1
sed -i 's/^default=[0-9]\+/default=0/' '/boot/grub/grub.conf' || return 1
cd /workspace || return 1
return 0
}

EnterStage() {
set -x
echo "[Desktop Entry]" > '/root/Desktop/v3.5 Update Combo/scripts/next.desktop' || return 1
echo "Encoding=UTF-8" >> '/root/Desktop/v3.5 Update Combo/scripts/next.desktop' || return 1
echo "Type=Application" >> '/root/Desktop/v3.5 Update Combo/scripts/next.desktop' || return 1
echo "Exec=konsole -e script -f -c 'set -x; cd /root/Desktop/v3.5\\ Update\\ Combo; ./scripts/${1}.sh' /root/Desktop/v3.5\\ Update\\ Combo/logs/Stage${1}.txt" >> '/root/Desktop/v3.5 Update Combo/scripts/next.desktop' || return 1
echo "Terminal=false" >> '/root/Desktop/v3.5 Update Combo/scripts/next.desktop' || return 1
echo "Name=v3.5 Update Combo" >> '/root/Desktop/v3.5 Update Combo/scripts/next.desktop' || return 1
echo "Categories=Applocation" >> '/root/Desktop/v3.5 Update Combo/scripts/next.desktop' || return 1
set +x
for ((i = 10; i > 0; i--)); do
echo -ne "Press any key in $i to abort automatic reboot... \r"
if read -rs -n 1 -t 1; then
echo -e "\nReboot aborted. "
sleep 1
cp -f ~/.bashrc /root/Desktop/v3.5\ Update\ Combo/scripts/trap
echo 'set -x' >> /root/Desktop/v3.5\ Update\ Combo/scripts/trap
echo 'set +e' >> /root/Desktop/v3.5\ Update\ Combo/scripts/trap
echo 'source pkgtool' >> /root/Desktop/v3.5\ Update\ Combo/scripts/trap
exec bash --rcfile /root/Desktop/v3.5\ Update\ Combo/scripts/trap -i
exit
fi
done
echo -e "\nRebooting now... "
sleep 1
reboot
}

export PATH=/opt/Cross64/bin:/opt/NewRoot/usr/bin:/opt/NewRoot/usr/sbin:$PATH
trap 'operationerror' ERR
set +e
