#!/bin/bash

# Release script for rust-skills
# Updates version in plugin.json and work.md, then commits and pushes

set -e

# Get current version from plugin.json
CURRENT_VERSION=$(grep '"version"' .claude-plugin/plugin.json | head -1 | sed 's/.*"version": "\(.*\)".*/\1/')

echo "Current version: $CURRENT_VERSION"

# Split version into parts
IFS='.' read -r MAJOR MINOR PATCH <<< "$CURRENT_VERSION"

# Increment patch version
NEW_PATCH=$((PATCH + 1))
NEW_VERSION="$MAJOR.$MINOR.$NEW_PATCH"

echo "New version: $NEW_VERSION"

# Update plugin.json
sed -i '' "s/\"version\": \"$CURRENT_VERSION\"/\"version\": \"$NEW_VERSION\"/" .claude-plugin/plugin.json

echo "Version updated to $NEW_VERSION"

# Commit and push
git add -A
git commit -m "auto"
git push

echo "Release $NEW_VERSION pushed successfully!"
