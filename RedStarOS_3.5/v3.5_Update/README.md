# RedStarOS 3.5 Update - Complete Installation Guide

## 📋 Table of Contents
- [What is This?](#what-is-this)
- [What Does It Do?](#what-does-it-do)
- [Before You Start](#before-you-start)
- [Installation Instructions](#installation-instructions)
- [Troubleshooting](#troubleshooting)
- [Technical Details](#technical-details)
- [Credits & Acknowledgments](#credits--acknowledgments)

---

## What is This?

This is an **unofficial upgrade package** for Red Star OS 3.0 (North Korea's Linux distribution). It upgrades your system from the old 2.6.38 kernel to a modern 5.4 x86_64 kernel, along with updated development tools and system libraries.

**⚠️ IMPORTANT WARNINGS:**
- This is for educational and research purposes only
- Red Star OS contains surveillance and tracking components
- **Never install on a real computer** - use only in isolated virtual machines
- Disconnect from all networks during installation
- The original OS contains watermarking and monitoring systems

---

## What Does It Do?

This update performs the following upgrades:

### System Components
- **Kernel**: 2.6.38 → 5.4.300 x86_64 (with 4.19.325 also available)
- **GCC Compiler**: 4.4.x → 6.5.0 / 9.5.0  
- **glibc**: 2.10.x → 2.23 / 2.34
- **binutils**: Old version → 2.34
- **Python**: Adds Python 3.7.6

### Development Tools
- Updated GNU toolchain (make, autoconf, automake, libtool)
- Cross-compilation support for x86_64
- Modern build tools (CMake 3.12.4, busybox 1.32.1)
- Debugging tools (GDB 7.12 / 8.3)

### Security Improvements
- **Automatic SELinux disabling** (prevents permission errors)
- **Security daemon bypass** (stops `securityd`, `opprc`, `scnprc`)
- **Watermarking prevention** (disables `rtscan` kernel module)
- **Monitoring component removal** (removes autostart surveillance)

---

## Before You Start

###  Requirements

**✅ Essential:**
1. **Red Star OS 3.0** installed in a virtual machine (VirtualBox, VMware, KVM)
2. **Root access** enabled (see "Enabling Root" below)
3. **At least 10GB** free disk space on `/`
4. **At least 2GB RAM** allocated to the VM
5. **All packages** in the `packages/` folder (52 packages included)

**✅ Recommended:**
- Backup your VM before starting
- Disconnect VM from all networks
- Use VPN on host machine
- Snapshot the VM state before installation

### ⚠️ Enabling Root Access

Red Star OS disables root by default. You MUST enable it first:

**Method 1: Using rootsetting (Recommended)**
```bash
/usr/sbin/rootsetting
```
This opens a GUI tool. Enter your user password, then set a root password.

**Method 2: From Desktop**
1. Click Applications → System → Root Terminal
2. Follow the prompts to set root password

**Method 3: If rootsetting doesn't work**
The installer will try to enable root automatically, but may fail due to security restrictions.

### 🔍 Verifying Root Access

After enabling root, verify it works:
```bash
su - root
# Enter root password
whoami
# Should print: root
```

---

## Installation Instructions

### Step 1: Prepare the System

1. **Copy the update folder** to your Desktop:
```bash
# The folder should be at /root/Desktop/v3.5 Update Combo/
```

2. **Open a terminal** (Applications → System → Terminal)

3. **Navigate to the folder**:
```bash
cd '/root/Desktop/v3.5 Update Combo/'
ls -la
```

You should see:
- `scripts/` folder
- `packages/` folder (with 52 .tar files)
- `Install.desktop` file

### Step 2: Make Scripts Executable

```bash
chmod +x scripts/*.sh
```

### Step 3: Start the Installation

**Choose ONE of these methods:**

#### Method A: Automatic Installation (Easiest)

Double-click the `Install.desktop` icon on your desktop, or run:

```bash
cd '/root/Desktop/v3.5 Update Combo/scripts/'
sudo ./1.sh
```

The installer will automatically:
- ✅ Check for root privileges
- ✅ Disable SELinux completely
- ✅ Stop all security daemons
- ✅ Create necessary directories
- ✅ Install all packages
- ✅ Build cross-compilation toolchain
- ✅ Compile and install new kernel
- ✅ Prepare system for reboot

#### Method B: Manual Step-by-Step (For Advanced Users)

```bash
# Step 1: Switch to root
su - root

# Step 2: Navigate to scripts
cd '/root/Desktop/v3.5 Update Combo/scripts/'

# Step 3: Source the utilities
source ./pkgutils.sh

# Step 4: Disable security (critical!)
check_root
disable_selinux
disable_security_components

# Step 5: Run installation
./1.sh
```

### Step 4: Monitor Installation

The installation will:
1. Display progress in the terminal
2. Create log files in `logs/` folder
3. Show package compilation progress
4. **Take 2-6 hours** depending on your CPU

**📊 Progress Indicators:**
- "Installing bc" → Basic utilities
- "Installing gcc" → Compiler (takes longest)  
- "Installing Kernel" → Almost done!
- "Press any key in 10 to abort reboot" → Success!

### Step 5: Reboot

After Stage 1 completes:
1. System will prompt you to reboot in 10 seconds
2. Press any key to cancel auto-reboot (optional)
3. Reboot manually: `reboot`

After reboot:
1. System should boot with new kernel
2. If a `next.desktop` icon appears, double-click it to continue Stage 2
3. Stage 2 is minimal and completes quickly

### Step 6: Verify Installation

After final reboot:

```bash
# Check kernel version
uname -r
# Should show: 5.4.300 or similar

# Check GCC version
gcc --version
# Should show: gcc (GCC) 6.5.0 or 9.5.0

# Check 64-bit support
uname -m
# Should show: x86_64
```

---

## Troubleshooting

### Problem: "Permission denied" when creating /bin/pkgtool

**Symptoms:**
```
ln: creating symbolic link `/bin/pkgtool': Permission denied
```

**Solutions:**
1. **Automatic Fix (Built-in):** The improved installer automatically tries multiple locations. Just continue.

2. **Manual Fix:**
```bash
# Disable SELinux immediately
setenforce 0

# Kill security daemons
killall -9 securityd opprc scnprc artsd

# Verify they're dead
ps aux | grep -E "securityd|opprc|scnprc"
# Should return nothing

# Try installation again
cd '/root/Desktop/v3.5 Update Combo/scripts/'
./1.sh
```

3. **Nuclear Option:**
```bash
# If still failing, use the alternative path
export PATH=/usr/local/bin:$PATH
ln -sf '/root/Desktop/v3.5 Update Combo/scripts/pkgutils.sh' /usr/local/bin/pkgtool
```

### Problem: System reboots unexpectedly during installation

**Cause:** `securityd` daemon detected file modifications and forced reboot.

**Solution:**
```bash
# Before running installer:
killall -9 securityd opprc scnprc

# Disable the rtscan kernel module
python -c "import fcntl; fcntl.ioctl(open('/dev/res', 'wb'), 29187)"

# Remove autostart files
mv /usr/share/autostart/scnprc.desktop /root/scnprc.desktop.disabled
mv /etc/init/ctguard.conf /root/ctguard.conf.disabled

# Now run installer
cd '/root/Desktop/v3.5 Update Combo/scripts/'
./1.sh
```

### Problem: "Package not found" error

**Symptoms:**
```
ERROR: Package not found: /root/Desktop/v3.5 Update Combo/packages/gcc-6.5.0.tar.xz
```

**Solutions:**
1. Verify package location:
```bash
ls -la '/root/Desktop/v3.5 Update Combo/packages/' | wc -l
# Should show around 52-54 files
```

2. Check folder name (exact spacing matters):
```bash
pwd
# Should be: /root/Desktop/v3.5 Update Combo
```

3. If folder is named differently, either:
   - Rename it to exactly: `v3.5 Update Combo`
   - Or edit scripts to match your folder name

### Problem: Yum fails to install Development Tools

**Symptoms:**
```
yum install @"Development Tools" failed
```

**Solution:** This is **non-critical**. The installer includes these tools in packages and will continue anyway.

If you want to fix it:
```bash
# Mount the Red Star OS installation ISO
mount /dev/cdrom /media

# Try yum again
yum --disablerepo=* --enablerepo=c6-media install @"Development Tools"
```

### Problem: Compilation fails with "out of memory"

**Cause:** VM has insufficient RAM (gcc compilation is memory-intensive).

**Solution:**
1. Increase VM RAM to at least 2GB (4GB recommended)
2. Add swap space:
```bash
dd if=/dev/zero of=/swapfile bs=1M count=2048
chmod 600 /swapfile
mkswap /swapfile
swapon /swapfile
```

### Problem: Installation hangs at "Compiling"

**Symptom:** Package compilation appears frozen.

**What's happening:** Large packages (gcc, kernel) take 30-120 minutes to compile.

**Solution:**
1. **Be patient!** Open another terminal and check:
```bash
top
# Look for 'make' or 'gcc' processes using CPU
```

2. Check log files:
```bash
tail -f /root/Desktop/v3.5\ Update\ Combo/logs/installation.log
```

3. If truly hung (no CPU activity for 10+ minutes):
```bash
killall make
cd '/root/Desktop/v3.5 Update Combo/scripts/'
./1.sh  # Restart installation
```

### Problem: SELinux re-enables after reboot

**Symptom:** After reboot, `getenforce` shows "Enforcing"

**Solution:**
```bash
# Check GRUB configuration
grep "selinux=0" /boot/grub/grub.conf

# If not present, add it manually:
vi /boot/grub/grub.conf

# Find the kernel line (looks like):
# kernel /vmlinuz-... root=...

# Add selinux=0 to the end:
# kernel /vmlinuz-... root=... selinux=0

# Save and reboot
```

### Problem: Can't find log files

**Location:** All logs are in:
```bash
/root/Desktop/v3.5\ Update\ Combo/logs/
```

**Key log files:**
- `installation.log` - Main installation log
- `yum_install.log` - Yum package installation  
- `extract_*.log` - Individual package extraction
- `Stage1.txt` - Complete Stage 1 output
- `Stage2.txt` - Complete Stage 2 output

**View logs:**
```bash
cd '/root/Desktop/v3.5 Update Combo/logs/'
less installation.log
# Press 'q' to quit
```

---

## Technical Details

### What Gets Modified

**System Directories:**
- `/usr/bin`, `/usr/lib`, `/usr/include` - Updated system tools
- `/usr/src/kernels/` - New kernel source
- `/boot/` - New kernel image and initrd
- `/opt/Cross64/` - Cross-compilation toolchain
- `/opt/NewRoot/` - Isolated build environment
- `/workspace/` - Temporary build directory

**Configuration Files:**
- `/boot/grub/grub.conf` - Adds `selinux=0` parameter
- `/etc/selinux/config` - Sets SELINUX=disabled
- `~/.bashrc` - Adds `pkgtool` alias (fallback)

**Backups:**
All modified config files are backed up to:
```
/root/Desktop/v3.5 Update Combo/backup/
```

### Security Components Disabled

The installer disables these Red Star OS surveillance components:

| Component | Purpose | Disable Method |
|-----------|---------|----------------|
| **SELinux** | File access control | `setenforce 0` + grub parameter |
| **securityd** | File integrity monitor | `killall -9 securityd` |
| **opprc** | Media watermarking daemon | `killall -9 opprc` |
| **scnprc** | Antivirus/scanner | `killall -9 scnprc` |
| **rtscan** | Kernel protection module | Python ioctl disable |
| **libos.so** | OS validation library | Replaced with defused version |
| **ctguard** | System monitor | Autostart removed |

**What This Means:**
- You can modify system files without forced reboots
- Media files won't be watermarked with your serial number
- System won't report activities to monitoring services
- SELinux won't block legitimate operations

**Note:** These are North Korean surveillance systems. Disabling them is necessary for the update to work, but also demonstrates why Red Star OS should never be used outside isolated VMs.

### Package List

**Included in this update (52 packages):**

**Core Tools:**
- bc-1.07.1, make-4.2.1, sed-4.4, gawk-4.2.1, cpio-2.13

**Compression:**
- zlib-1.2.11, libarchive-3.5.3, busybox-1.32.1

**Build System:**
- autoconf-2.69, automake-1.15, libtool-2.4.6, cmake-3.12.4
- m4-1.4.18, autogen-5.18.16, bison-3.5.4

**Math Libraries:**
- gmp-4.3.2, gmp-6.2.1
- mpfr-2.4.2, mpfr-4.1.0
- mpc-0.8.1, mpc-1.2.1  
- isl-0.14, isl-0.24

**Compilers & Debuggers:**
- gcc-6.5.0, gcc-9.5.0
- binutils-2.34
- gdb-7.12, gdb-8.3

**Standard Libraries:**
- glibc-2.23, glibc-2.34
- ncurses-6.0, guile-1.8.8, expat-2.2.10
- libffi-3.3, libiconv-1.16

**Security Libraries:**
- openssl-1.0.2u, gnutls-3.3.30
- nettle-3.4.1, libtasn1-4.10, p11-kit-0.23.18.1
- libunistring-1.1, unbound-1.12.0

**Utilities:**
- wget-1.19.5, cvs-1.12.13, coreutils-8.32
- texinfo-6.8, help2man-1.47.17

**Programming Languages:**
- Python-3.7.6

**Kernels (choose one during install):**
- linux-3.19.8 (older, more stable)
- linux-4.19.325 (stable LTS)
- linux-5.4.300 (modern LTS) ← **Recommended**

### Installation Stages

**Stage 1** (Main installation - 2-6 hours):
1. System preparation (SELinux, security bypass)
2. Development tools installation
3. Host system compiler upgrade
4. Cross-compilation toolchain build
5. x86_64 system root creation  
6. Kernel compilation and installation
7. GRUB configuration update
8. Reboot trigger

**Stage 2** (Cleanup - 5 minutes):
1. Workspace cleanup
2. Final configuration
3. System verification

### Disk Space Usage

**During Installation:**
- `/workspace/` - ~5GB (temporary)
- `/opt/Cross64/` - ~2GB
- `/opt/NewRoot/` - ~1.5GB
- `/usr/src/kernels/` - ~1GB

**After Installation:**
- Workspace cleaned automatically
- Cross-compilation tools remain (~3.5GB)
- New kernel and modules (~500MB)

**Total:** ~4-5GB permanent increase

---

## FAQ

**Q: Why does this exist?**  
A: Red Star OS is an interesting curiosity for security researchers. This update makes it more usable for analysis and brings it closer to modern Linux standards.

**Q: Is this safe to use?**  
A: Only in an isolated VM with no network access. Red Star OS is surveillance software. This update removes some monitoring but cannot guarantee all tracking is disabled.

**Q: Will this remove all surveillance?**  
A: No. It removes known components (securityd, opprc, watermarking), but unknown backdoors may exist. **Never trust Red Star OS** with real data.

**Q: Can I use this on Red Star OS 2.0?**  
A: No, this is specifically for version 3.0. Version 2.0 has a different architecture.

**Q: Why does compilation take so long?**  
A: GCC and the kernel are huge projects (millions of lines of code). A full GCC compilation takes 1-2 hours even on modern CPUs.

**Q: Can I stop and resume later?**  
A: No. The installation must complete in one run. If it fails, you'll need to restart from the beginning (or at least from a clean workspace).

**Q: What if I encounter errors?**  
A: Check the [Troubleshooting](#troubleshooting) section. Most errors are due to:
1. SELinux/security daemons still running
2. Insufficient RAM/disk space
3. Incorrect folder paths

**Q: Can I contribute improvements?**  
A: Yes! This project is open for improvements. See the Credits section for the original sources.

**Q: Why x86_64 and not ARM or other architectures?**  
A: Red Star OS 3.0 is primarily x86-based. The cross-compilation setup targets x86_64 to modernize while maintaining compatibility.

**Q: Will this break my existing Red Star OS?**  
A: Potentially yes. That's why you should:
1. Only use in a VM
2. Take a snapshot before starting
3. Backup any data (though there shouldn't be any real data in Red Star OS)

---

## Credits & Acknowledgments

This update package builds upon work from multiple sources:

### Original Research & Tools

**RedStar Tools** by **takeshixx**
- GitHub: https://github.com/takeshixx/redstar-tools
- Pioneering work on Red Star OS security analysis
- libos.so defusing technique
- Security component bypass methods

**Chaos Computer Club (CCC)**
- Red Star OS security research (2015-2016)
- Watermarking system documentation
- Surveillance mechanism analysis

**kimfetch** by **JiayuanWen**
- GitHub: https://github.com/JiayuanWen/kimfetch
- System information script for Red Star OS
- Demonstrates workarounds for missing shell features

**RedStarPackages** by **gdwnldsKSC**
- GitHub: https://github.com/gdwnldsKSC/RedStarPackages
- Red Star OS 3.0 package compilation work
- RPM building strategies for Fedora 11 base

### Package Sources

All packages are from official upstream sources:
- **GNU Project** - GCC, binutils, glibc, coreutils, etc.
- **Python Software Foundation** - Python 3.7.6
- **Linux Kernel Archives** - Kernel 3.19.8, 4.19.325, 5.4.300
- **OpenSSL Project** - OpenSSL 1.0.2u
- Various other open-source projects

### Community Contributions

- Research from security conferences (CCC, DEF CON)
- Online discussions and analysis
- Virtual machine testing volunteers

### This Project

**Enhancements in this package:**
- Automatic SELinux disabling at multiple levels
- Comprehensive security bypass (all known components)
- Multi-fallback symlink creation
- Improved error handling and logging
- Resilient installation wrapper
- Modern kernel support (5.4 LTS)
- Complete documentation for average users

**Version:** 3.5 Enhanced Edition  
**Last Updated:** October 2025  
**License:** Educational/Research Use Only

**Disclaimer:** This is an unofficial community project. Not affiliated with or endorsed by the Democratic People's Republic of Korea. Use at your own risk for educational and research purposes only.

---

## Legal & Ethical Notice

**⚠️ CRITICAL WARNINGS:**

1. **Privacy Risk:** Red Star OS is surveillance software created by a totalitarian regime. It tracks everything you do.

2. **Security Risk:** Even with this update, unknown backdoors and monitoring may exist. Never use with real data.

3. **Legal Risk:** Depending on your country, possessing or using North Korean software may have legal implications. Check your local laws.

4. **Ethical Responsibility:** This tool is for:
   - ✅ Security research
   - ✅ Academic study  
   - ✅ Technical education
   - ❌ NOT for circumventing sanctions
   - ❌ NOT for actual use as a daily OS
   - ❌ NOT for distribution in North Korea

**Recommended Usage:**
- Isolated VMs only
- No network access
- No real data
- VPN on host system
- For research purposes only

---

## Support & Contact

**For Issues:**
1. Check the [Troubleshooting](#troubleshooting) section
2. Review log files in `logs/` folder
3. Search for similar issues in related projects

**Resources:**
- Original v3.5 Update: Check Red Star OS community forums
- RedStar Tools: https://github.com/takeshixx/redstar-tools
- Security Research: CCC talks and papers

**This README last updated:** October 2025

---

**Remember:** Red Star OS is not a toy. It's a tool of oppression. Use it only for educational purposes to understand and counter such systems. Never use it with real data or as an actual operating system.

Stay safe, stay curious, and use this knowledge for good.
