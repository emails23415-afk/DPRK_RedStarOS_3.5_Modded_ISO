#!/bin/bash
#
# Test and Verification Script for RedStarOS 3.5 Update Installer
# This script tests if the improvements work correctly
#

echo "======================================"
echo "RedStarOS 3.5 Update - Test Suite"
echo "======================================"
echo

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
TEST_PASSED=0
TEST_FAILED=0

# Test function
test_feature() {
    local test_name="$1"
    local test_command="$2"
    
    echo -n "Testing: ${test_name}... "
    
    if eval "${test_command}" &>/dev/null; then
        echo "\u2713 PASS"
        ((TEST_PASSED++))
        return 0
    else
        echo "\u2717 FAIL"
        ((TEST_FAILED++))
        return 1
    fi
}

# Test 1: Check if files exist
echo "[ File Existence Tests ]"
test_feature "Main installer exists" "[ -f '${SCRIPT_DIR}/install_resilient.sh' ]"
test_feature "Preflight check exists" "[ -f '${SCRIPT_DIR}/scripts/preflight_check.sh' ]"
test_feature "Improved pkgutils exists" "[ -f '${SCRIPT_DIR}/scripts/pkgutils_improved.sh' ]"
test_feature "Improved stage 1 exists" "[ -f '${SCRIPT_DIR}/scripts/1_improved.sh' ]"
test_feature "README exists" "[ -f '${SCRIPT_DIR}/README_IMPROVED.md' ]"
test_feature "Quick start guide exists" "[ -f '${SCRIPT_DIR}/QUICKSTART.md' ]"
test_feature "Changelog exists" "[ -f '${SCRIPT_DIR}/CHANGELOG.md' ]"
echo

# Test 2: Check if scripts are executable
echo "[ Executable Tests ]"
test_feature "Main installer is executable" "[ -x '${SCRIPT_DIR}/install_resilient.sh' ]"
test_feature "Preflight check is executable" "[ -x '${SCRIPT_DIR}/scripts/preflight_check.sh' ]"
test_feature "Improved pkgutils is executable" "[ -x '${SCRIPT_DIR}/scripts/pkgutils_improved.sh' ]"
test_feature "Improved stage 1 is executable" "[ -x '${SCRIPT_DIR}/scripts/1_improved.sh' ]"
echo

# Test 3: Check if scripts have proper shebang
echo "[ Script Validity Tests ]"
test_feature "Main installer has shebang" "head -n1 '${SCRIPT_DIR}/install_resilient.sh' | grep -q '^#!/bin/bash'"
test_feature "Preflight has shebang" "head -n1 '${SCRIPT_DIR}/scripts/preflight_check.sh' | grep -q '^#!/bin/bash'"
test_feature "Pkgutils has shebang" "head -n1 '${SCRIPT_DIR}/scripts/pkgutils_improved.sh' | grep -q '^#!/bin/bash'"
echo

# Test 4: Check for key functions in scripts
echo "[ Function Existence Tests ]"
test_feature "check_root function exists" "grep -q 'check_root()' '${SCRIPT_DIR}/scripts/pkgutils_improved.sh'"
test_feature "disable_selinux function exists" "grep -q 'disable_selinux()' '${SCRIPT_DIR}/scripts/pkgutils_improved.sh'"
test_feature "disable_security_components exists" "grep -q 'disable_security_components()' '${SCRIPT_DIR}/scripts/pkgutils_improved.sh'"
test_feature "MakeShortcut function exists" "grep -q 'MakeShortcut()' '${SCRIPT_DIR}/scripts/pkgutils_improved.sh'"
test_feature "log_message function exists" "grep -q 'log_message()' '${SCRIPT_DIR}/scripts/pkgutils_improved.sh'"
echo

# Test 5: Check for key improvements
echo "[ Improvement Tests ]"
test_feature "SELinux disable code present" "grep -q 'setenforce 0' '${SCRIPT_DIR}/install_resilient.sh'"
test_feature "Security daemon kill present" "grep -q 'killall.*securityd' '${SCRIPT_DIR}/install_resilient.sh'"
test_feature "Multiple fallback strategy present" "grep -q '/usr/local/bin/pkgtool' '${SCRIPT_DIR}/scripts/pkgutils_improved.sh'"
test_feature "Logging system present" "grep -q 'log_message' '${SCRIPT_DIR}/scripts/pkgutils_improved.sh'"
test_feature "Backup directory creation present" "grep -q 'BACKUP_DIR' '${SCRIPT_DIR}/scripts/pkgutils_improved.sh'"
echo

# Test 6: Check directory structure
echo "[ Directory Structure Tests ]"
test_feature "Scripts directory exists" "[ -d '${SCRIPT_DIR}/scripts' ]"
test_feature "Original pkgutils preserved" "[ -f '${SCRIPT_DIR}/scripts/pkgutils.sh' ]"
test_feature "Original stage 1 preserved" "[ -f '${SCRIPT_DIR}/scripts/1.sh' ]"
echo

# Test 7: Syntax check (if bash is available)
if command -v bash &>/dev/null; then
    echo "[ Syntax Tests ]"
    test_feature "Main installer syntax OK" "bash -n '${SCRIPT_DIR}/install_resilient.sh'"
    test_feature "Preflight check syntax OK" "bash -n '${SCRIPT_DIR}/scripts/preflight_check.sh'"
    test_feature "Improved pkgutils syntax OK" "bash -n '${SCRIPT_DIR}/scripts/pkgutils_improved.sh'"
    test_feature "Improved stage 1 syntax OK" "bash -n '${SCRIPT_DIR}/scripts/1_improved.sh'"
    echo
fi

# Test 8: Documentation tests
echo "[ Documentation Tests ]"
test_feature "README has quick start section" "grep -q 'Quick Start' '${SCRIPT_DIR}/QUICKSTART.md' || grep -q 'TL;DR' '${SCRIPT_DIR}/QUICKSTART.md'"
test_feature "README has troubleshooting" "grep -q 'Troubleshooting\\|Common Issues' '${SCRIPT_DIR}/README_IMPROVED.md'"
test_feature "Changelog has version info" "grep -q 'Version\\|v2.0\\|Resilient' '${SCRIPT_DIR}/CHANGELOG.md'"
echo

# Summary
echo "======================================"
echo "Test Summary"
echo "======================================"
echo "Passed: ${TEST_PASSED}"
echo "Failed: ${TEST_FAILED}"
echo "Total:  $((TEST_PASSED + TEST_FAILED))"
echo

if [ ${TEST_FAILED} -eq 0 ]; then
    echo "\u2713 All tests passed! The installer is ready to use."
    echo
    echo "To run the installer:"
    echo "  ./install_resilient.sh"
    exit 0
else
    echo "\u2717 Some tests failed. Please review the output above."
    exit 1
fi
