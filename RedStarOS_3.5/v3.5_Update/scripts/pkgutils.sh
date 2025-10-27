#!/bin/bash
#
# RedStarOS Package Utilities - Enhanced Edition
# Automatic SELinux handling, security bypass, and resilient operations
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
        command -v /usr/sbin/rootsetting &>/dev/null && /usr/sbin/rootsetting
        return 1
    fi
    return 0
}

# Disable SELinux completely
disable_selinux() {
    log_message "INFO" "Disabling SELinux"
    command -v setenforce &>/dev/null && setenforce 0 2>/dev/null || true
    
    # Persistent disable in grub
    for grub_conf in /boot/grub/grub.conf /boot/grub2/grub.cfg /etc/grub.conf; do
        if [ -f "${grub_conf}" ] && ! grep -q "selinux=0" "${grub_conf}"; then
            cp "${grub_conf}" "${BACKUP_DIR}/$(basename ${grub_conf}).bak" 2>/dev/null
            sed -i'.bak' '/kernel.*vmlinuz/ s/$/ selinux=0/' "${grub_conf}" 2>/dev/null || true
        fi
    done
    
    # Disable in config
    [ -f /etc/selinux/config ] && sed -i 's/^SELINUX=.*/SELINUX=disabled/' /etc/selinux/config 2>/dev/null || true
    return 0
}

# Disable RedStarOS security components
disable_security_components() {
    log_message "INFO" "Disabling security components"
    killall -9 securityd opprc scnprc artsd 2>/dev/null || true
    
    # Disable rtscan kernel module
    [ -c /dev/res ] && echo -e "import fcntl\nfcntl.ioctl(open('/dev/res', 'wb'), 29187)" | python 2>/dev/null || true
    
    # Remove autostarts
    for file in /usr/share/autostart/scnprc.desktop /etc/init/ctguard.conf; do
        [ -f "${file}" ] && mv "${file}" "${BACKUP_DIR}/$(basename ${file}).disabled" 2>/dev/null || true
    done
    return 0
}

# Enhanced MakeShortcut with multiple fallback strategies
MakeShortcut() {
    log_message "INFO" "Creating pkgtool shortcut"
    local script_path="${SCRIPT_DIR}/pkgutils.sh"
    
    # Try multiple locations with fallback
    for bin_dir in /bin /usr/local/bin /usr/bin; do
        if rm -f "${bin_dir}/pkgtool" 2>/dev/null && ln -sf "${script_path}" "${bin_dir}/pkgtool" 2>/dev/null; then
            log_message "INFO" "Created pkgtool at ${bin_dir}/pkgtool"
            return 0
        fi
    done
    
    # Fallback: add to bashrc
    if ! grep -q "alias pkgtool=" ~/.bashrc 2>/dev/null; then
        echo "alias pkgtool='${script_path}'" >> ~/.bashrc 2>/dev/null
        log_message "INFO" "Created pkgtool alias in ~/.bashrc"
    fi
    return 0
}
operationerror() {
kdialog --title "Operation Cannot Be Completed" --error "An unexpected critical error has occured during the installation. \nPlease copy the console output and send them to the development team of Red Star OS 3.5 on discord. \nDiscord server invite link: discord.gg/MY68R2Quq5\n\nWe apologize for the inconvenience. \nThe installation script will now stop. "
return 1
}
scripterror() {
rm -f '/root/Desktop/v3.5 Update Combo/scripts/next.desktop'
kdialog --title "Failed To Install v3.5 Update Combo" --error "An unexpected critical error has occured during the installation. \nPlease copy the console output and send them to the development team of Red Star OS 3.5 on discord. \nDiscord server invite link: discord.gg/MY68R2Quq5\n\nWe apologize for the inconvenience. \nThe installation script will now stop. "
set +x
cp -f ~/.bashrc /root/Desktop/v3.5\ Update\ Combo/scripts/trap
echo 'set -x' >> /root/Desktop/v3.5\ Update\ Combo/scripts/trap
echo 'set +e' >> /root/Desktop/v3.5\ Update\ Combo/scripts/trap
echo 'source pkgtool' >> /root/Desktop/v3.5\ Update\ Combo/scripts/trap
exec bash --rcfile /root/Desktop/v3.5\ Update\ Combo/scripts/trap -i
exit
}
yumerror() {
kdialog --title "Failed To Install v3.5 Update Combo" --error "Failed to install necessary development tools via 'yum install'. \nPlease make sure the Red Star OS 3.5 installation image is inserted into the device and the built-in yum repo on the image can be accessed normally. \nIf you've already installed all components under the development category and do not need to repeat this process, just ignore this message. \n\nWe apologize for the disruption. \nClick 'OK' to continue... "
return 0
}
title() {
set -x
printf '\033]0;%s\007' "$*" || return 1
}
nop() { return 0; }
Extract() {
set -x
if [[ -n "${3}" ]]; then
title "${3}" || return 1
else
title "Extracting ${1}" || return 1
fi
cd /workspace || return 1
tar xvf "/root/Desktop/v3.5 Update Combo/packages/${1}.tar.${2}" || return 1
cd "${1}" || return 1
return 0
}
CleanUp() {
set -x
if [[ -n "${2}" ]]; then
title "${2}" || return 1
else
title "Cleaning ${1}" || return 1
fi
cd /workspace || return 1
rm -rf "${1}" || return 1
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
echo "Exec=konsole -e script -f -c 'set -x; cd /root/Desktop/v3.5\ Update\ Combo; ./scripts/${1}.sh' /root/Desktop/v3.5\ Update\ Combo/logs/Stage${1}.txt" >> '/root/Desktop/v3.5 Update Combo/scripts/next.desktop' || return 1
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
