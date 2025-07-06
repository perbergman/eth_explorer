#!/bin/bash
# Remove large files from git history

echo "Removing large files from git history..."

# Use git filter-repo if available, otherwise use filter-branch
if command -v git-filter-repo &> /dev/null; then
    git filter-repo --path eth_explorer.log --invert-paths --force
else
    git filter-branch --force --index-filter \
        'git rm --cached --ignore-unmatch eth_explorer.log' \
        --prune-empty --tag-name-filter cat -- --all
fi

# Clean up
git reflog expire --expire=now --all
git gc --prune=now --aggressive

echo "Done! Now try pushing again."