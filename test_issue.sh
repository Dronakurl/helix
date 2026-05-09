#!/bin/bash

# Create test directory structure
mkdir -p /tmp/test_helix_completion/"Some Directory"
mkdir -p /tmp/test_helix_completion/"Some Other Directory"
touch /tmp/test_helix_completion/"Some Directory"/file1.txt
touch /tmp/test_helix_completion/"Some Other Directory"/file2.txt

cd /tmp/test_helix_completion

# Try to use helix to reproduce the issue
echo "Directory structure created. Manual testing needed."
echo "Run: hx"
echo "Then type: :change-current-directory Some<TAB>"
echo "Expected: should complete to 'Some Directory'"
echo "Then press TAB again"
echo "Expected: should cycle to 'Some Other Directory' or show completions"
