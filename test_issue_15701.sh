#!/bin/bash

# This script sets up a test environment for issue #15701
# It creates directories with spaces and provides instructions for manual testing

TEST_DIR="/tmp/helix_test_15701"

# Clean up any previous test
rm -rf "$TEST_DIR"

# Create test directory structure
mkdir -p "$TEST_DIR/Some Directory/Subdir1"
mkdir -p "$TEST_DIR/Some Directory/Subdir2"
mkdir -p "$TEST_DIR/Some Other Directory"
touch "$TEST_DIR/Some Directory/file1.txt"
touch "$TEST_DIR/Some Directory/Subdir1/file2.txt"
touch "$TEST_DIR/Some Other Directory/file3.txt"

echo "Test environment created at: $TEST_DIR"
echo ""
echo "Directory structure:"
find "$TEST_DIR" -type d | sed "s|^$TEST_DIR/|  |"
echo ""
echo "Files:"
find "$TEST_DIR" -type f | sed "s|^$TEST_DIR/|  |"
echo ""
echo "========================================="
echo "Manual test instructions:"
echo "========================================="
echo ""
echo "1. Run helix: ./target/release/hx"
echo ""
echo "2. Type: :change-current-directory $TEST_DIR/Some"
echo ""
echo "3. Press TAB"
echo "   Expected: Should complete to '\$TEST_DIR/Some Directory' or show completion menu"
echo ""
echo "4. Press TAB again"
echo "   Expected: Should cycle to '\$TEST_DIR/Some Other Directory' or show subdirectories"
echo "   Actual (before fix): No completions shown"
echo ""
echo "5. If the first TAB adds quotes, try pressing TAB again"
echo "   Expected: Should show subdirectories (Subdir1, Subdir2) or cycle to next match"
echo "   Actual (before fix): No completions shown"
echo ""
echo "Note: If you have the fix applied, the completions should work."
echo ""
echo "To check if the fix is applied, run:"
echo "  git diff helix-term/src/commands/typed.rs | grep 'is_terminated'"
echo ""
echo "The fix should show:"
echo "  if token.is_terminated && !matches!(token.kind, TokenKind::Quoted(_)) {"
