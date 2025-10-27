# RedStarOS 3.5 Update - Quick Start Guide

## TL;DR - Just Get It Running!

```bash
# Step 1: Enable root access
/usr/sbin/rootsetting

# Step 2: Navigate to update directory
cd "/root/Desktop/v3.5 Update Combo"

# Step 3: Run resilient installer
./install_resilient.sh

# That's it! ✓
```

## What This Does

The resilient installer automatically:
1. ✓ Disables SELinux
2. ✓ Kills security daemons (securityd, opprc, scnprc)
3. ✓ Disables rtscan kernel module
4. ✓ Makes system directories writable
5. ✓ Creates necessary shortcuts with multiple fallback methods
6. ✓ Backs up important configuration files
7. ✓ Runs pre-flight system checks
8. ✓ Launches the installation process

## Before You Start

### ⚠️ IMPORTANT
- **Backup your data** (just in case)
- Have **at least 10GB free space**
- **Disconnect from network** (recommended)
- **Ensure stable power** (use UPS if available)

## Common Issues - Quick Fixes

### "Permission denied" error?
```bash
setenforce 0
killall -9 securityd
./install_resilient.sh
```

### System keeps rebooting?
```bash
killall -9 securityd opprc scnprc
python -c "import fcntl; fcntl.ioctl(open('/dev/res', 'wb'), 29187)"
./install_resilient.sh
```

### Can't find files?
```bash
# Check if you're in the right directory
pwd
ls -la packages/
# Should show many .tar.* files
```

## Alternative: Manual Control

If you want more control over the process:

```bash
# Step 1: Run pre-flight checks only
./scripts/preflight_check.sh

# Step 2: Review logs
cat logs/preflight.log

# Step 3: Run installation
./scripts/1_improved.sh
```

## During Installation

- **Don't interrupt** the process
- **Don't close** the terminal
- System will **reboot several times** (this is normal)
- Installation takes **30-60 minutes** depending on your hardware

## After Installation

The system will automatically:
1. Upgrade kernel to 5.4 x86_64
2. Update critical system components
3. Install development tools
4. Set up cross-compilation environment
5. Reboot when needed

## Need Help?

1. **Check logs**: `cat logs/master.log`
2. **Read full README**: `cat README_IMPROVED.md`
3. **Join Discord**: discord.gg/MY68R2Quq5

## Success Indicators

You'll know it's working when you see:
```
✓ Root privileges confirmed
✓ SELinux disabled
✓ Security components stopped
✓ System directories accessible
```

## Pro Tips

💡 **Set automatic login** in System Preferences to reduce password prompts during reboots

💡 **Keep terminal visible** to monitor progress

💡 **Don't panic** if you see lots of output - that's normal!

---

**Ready?** Just run: `./install_resilient.sh` 🚀
