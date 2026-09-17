#!/bin/bash
# Double-click this file in Finder to generate and open the Xcode project.
# It installs XcodeGen via Homebrew if needed, runs `xcodegen generate`,
# then opens the resulting UltrasEuropa.xcodeproj — see README.md for
# what each step does if you'd rather run them yourself in Terminal.

cd "$(dirname "$0")" || exit 1

echo "UltrasEuropa — setting up the Xcode project"
echo "============================================"
echo

if command -v git >/dev/null 2>&1 && [ -d .git ]; then
    echo "Pulling the latest changes from GitHub..."
    if ! git pull; then
        echo
        echo "git pull failed — see the error above. This doesn't use Xcode's"
        echo "GitHub sign-in at all, so if it's still failing, it's a plain git/network"
        echo "issue rather than an Xcode account problem. Continuing with what's"
        echo "already on disk."
        echo
    fi
    echo
fi

if ! command -v xcodegen >/dev/null 2>&1; then
    echo "XcodeGen isn't installed yet."
    if ! command -v brew >/dev/null 2>&1; then
        echo
        echo "Homebrew isn't installed either, so I can't install XcodeGen automatically."
        echo "Install Homebrew first from https://brew.sh, then double-click this file again."
        echo
        read -r -p "Press Enter to close this window..." _
        exit 1
    fi
    echo "Installing XcodeGen via Homebrew (this can take a minute)..."
    if ! brew install xcodegen; then
        echo
        echo "XcodeGen install failed — see the error above."
        read -r -p "Press Enter to close this window..." _
        exit 1
    fi
    echo
fi

echo "Generating UltrasEuropa.xcodeproj from project.yml..."
if ! xcodegen generate; then
    echo
    echo "xcodegen generate failed — see the error above."
    read -r -p "Press Enter to close this window..." _
    exit 1
fi

echo
echo "Opening the project in Xcode..."
open UltrasEuropa.xcodeproj

echo
echo "Done! Xcode should be opening now. You can close this window."
read -r -p "Press Enter to close this window..." _
