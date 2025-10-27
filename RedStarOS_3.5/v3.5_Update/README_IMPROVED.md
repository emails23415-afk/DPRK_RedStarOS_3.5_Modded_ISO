# RedStarOS 3.5 Update - Resilient Installation Guide

## Overview

This is an improved and resilient version of the RedStarOS 3.5 Update installer that addresses common installation issues, particularly permission denied errors when creating symlinks in `/bin` and other system directories.

## Key Improvements

### 1. **Automatic SELinux Disabling**
- Immediately disables SELinux using `setenforce 0`
- Modifies grub configuration for persistent SELinux disabling
- Updates `/etc/selinux/config` 
- Creates multiple fallback methods

### 2. **Security Component Bypass**
- Automatically kills `securityd` daemon
- Stops `opprc` and `scnprc` processes
- Disables `rtscan` kernel module
- Removes autostart configurations
- Replaces `libos.so` with defused version

### 3. **Multiple Fallback Strategies**
- Primary: Creates symlink in `/bin/pkgtool`
- Fallback 1: Creates symlink in `/usr/local/bin/pkgtool`
- Fallback 2: Creates symlink in `/usr/bin/pkgtool`
- Fallback 3: Adds alias to `~/.bashrc`
- Fallback 4: Direct script execution

### 4. **Enhanced Error Handling**
- Continues installation even if some steps fail
- Comprehensive logging to `logs/` directory
- Automatic backups of critical files
- Recovery shell on critical failures

### 5. **Better Compatibility**
- Works on RedStarOS 3.0, 3.5, and modern Linux systems
- Handles missing dependencies gracefully
- Adapts to different system configurations

## Installation Methods

### Method 1: Resilient Wrapper (Recommended)

This method provides maximum resilience and automatic preparation:

```bash
# Make executable
chmod +x install_resilient.sh

# Run as root
./install_resilient.sh
```

### Method 2: Pre-flight Check First

Run pre-flight checks separately before installation:

```bash
# Run pre-flight checks
chmod +x scripts/preflight_check.sh
./scripts/preflight_check.sh

# Then run installation
chmod +x scripts/1_improved.sh
./scripts/1_improved.sh
```

### Method 3: Original Method (with improvements)

Use the improved pkgutils directly:

```bash
# Source improved utilities
source scripts/pkgutils_improved.sh

# Run original installation script
chmod +x scripts/1.sh
./scripts/1.sh
```

## Pre-Installation Requirements

### Essential:
1. **Root Access**: Enable via `/usr/sbin/rootsetting` or `su`
2. **Disk Space**: At least 10GB free space on `/`
3. **Installation Media**: RedStarOS 3.5 update packages in `packages/` directory

### Recommended:
1. **Backup System**: Create backup of important data
2. **Network Disabled**: Disconnect from network during installation
3. **Power Source**: Ensure stable power supply (use UPS if available)

## Troubleshooting

### Problem: "Permission denied" when creating symlink

**Solution**: The resilient installer now handles this automatically by:
1. Disabling SELinux first
2. Killing security daemons
3. Trying multiple locations
4. Using fallback methods

If still failing, manually run:
```bash
setenforce 0
killall -9 securityd opprc scnprc
```

### Problem: SELinux re-enables after reboot

**Solution**: The installer modifies grub configuration. Verify:
```bash
grep "selinux=0" /boot/grub/grub.conf
```

If not present, manually add `selinux=0` to the kernel line.

### Problem: System reboots unexpectedly

**Cause**: `securityd` or `opprc` is still running

**Solution**: 
```bash
killall -9 securityd opprc scnprc
# Also replace libos.so with defused version
bash scripts/preflight_check.sh
```

### Problem: "Package file not found"

**Solution**: Ensure packages are in correct location:
```bash
ls -la "packages/"
# or try alternative path:
ls -la "/root/Desktop/v3.5 Update Combo/packages/"
```

### Problem: Yum installation fails

**Solution**: This is non-critical. The installer continues anyway.
- Ensure RedStarOS installation ISO is mounted
- Check if development tools are already installed
- Review logs in `logs/yum_install.log`

## File Structure

```
v3.5_Update/
├── install_resilient.sh          # Main resilient wrapper (NEW)
├── scripts/
│   ├── preflight_check.sh        # Pre-installation checks (NEW)
│   ├── pkgutils_improved.sh      # Improved utilities (NEW)
│   ├── pkgutils.sh               # Original utilities (backup)
│   ├── 1_improved.sh             # Improved stage 1 installer (NEW)
│   ├── 1.sh                      # Original stage 1 installer
│   └── 2.sh                      # Stage 2 installer
├── packages/                     # Installation packages
├── logs/                         # Installation logs (created)
└── backup/                       # Configuration backups (created)
```

## Logs and Diagnostics

All installation activities are logged:

- `logs/master.log` - Main installation log
- `logs/installation.log` - Detailed operation log
- `logs/preflight.log` - Pre-flight check results
- `logs/installation_stage1.log` - Stage 1 specifics
- `logs/yum_install.log` - Package installation log
- `logs/extract_*.log` - Individual package extraction logs

## Recovery

If installation fails:

1. **Check Logs**: Review log files in `logs/` directory
2. **Restore Backups**: Configuration backups are in `backup/` directory
3. **Recovery Shell**: On critical failure, a recovery shell is provided
4. **Manual Cleanup**: 
```bash
rm -rf /workspace /opt/Cross64 /opt/NewRoot
rm -f /bin/pkgtool /usr/local/bin/pkgtool /usr/bin/pkgtool
```

## Security Considerations

### What This Installer Does:

✓ Disables SELinux (required for installation)
✓ Kills security daemons (temporary)
✓ Makes system directories writable (temporary)
✓ Replaces libos.so with defused version

### After Installation:

You can re-enable security features if desired:
```bash
# Re-enable SELinux (not recommended on RedStarOS)
setenforce 1

# Restore original libos.so
cp backup/libos.so.0.0.0.backup /usr/lib/libos.so.0.0.0
```

## Differences from Original Installer

| Feature | Original | Improved |
|---------|----------|----------|
| SELinux Handling | None | Automatic disable |
| Error Recovery | Exits on first error | Continues with fallbacks |
| Logging | Minimal | Comprehensive |
| Backup | None | Automatic backups |
| Security Bypass | Manual | Automatic |
| Fallback Strategies | None | Multiple methods |
| Pre-flight Checks | None | Full system validation |

## Credits

- Based on RedStarOS 3.5 Update Combo
- Inspired by [redstar-tools](https://github.com/takeshixx/redstar-tools) by @takeshixx
- Enhanced for resilience and modern system compatibility

## Support

For issues or questions:
- Check logs in `logs/` directory
- Review this README thoroughly
- Join Discord: discord.gg/MY68R2Quq5

## License

Use at your own risk. This is provided as-is for educational and system upgrade purposes.

---

**IMPORTANT**: This installer makes significant system changes. Always backup your data before proceeding.
