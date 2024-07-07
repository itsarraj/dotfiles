#!/bin/bash

# Copy the prepare-commit-msg hook to the .git/hooks directory
cp scripts/hooks/prepare-commit-msg .git/hooks/prepare-commit-msg

# Make sure the hook is executable
chmod +x .git/hooks/prepare-commit-msg

# Add GitHub and GitLab remotes
git remote remove origin
git remote add github git@github.com:itsarraj/dotfiles.git
git remote add gitlab git@gitlab.com:itsarraj/dotfiles.git

# Verify that remotes have been added
echo "Git remotes configured:"
git remote -v
