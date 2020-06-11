#!/bin/bash

# The main identifier which everything hinges on
identifier="com.alectrona.post-macos-upgrade-recon"

# Default version of the build, you can leave this alone and specify as an argument like so: ./build.sh 1.7
version="1.0"

###### Variables below this point are not intended to be modified #####
daemonPlist="/Library/LaunchDaemons/${identifier}.plist"
daemonFileName="${daemonPlist##*/}"

if [[ -n "$1" ]]; then
    version="$1"
    echo "Version set to $version"
else
    echo "No version passed, using version $version"
fi

# Update the variables in the various files of the project
# If you know of a more elegant/efficient way to do this please create a PR
/usr/bin/sed -i '' "s#identifier=.*#identifier=\"$identifier\"#" "$PWD/postinstall.sh"

# Create clean temp build directories
/usr/bin/find /private/tmp/post-macos-upgrade-recon -mindepth 1 -delete &> /dev/null
/bin/mkdir -p /private/tmp/post-macos-upgrade-recon/files/Library/LaunchDaemons
/bin/mkdir -p /private/tmp/post-macos-upgrade-recon/files/Library/Scripts/
/bin/mkdir -p /private/tmp/post-macos-upgrade-recon/scripts
/bin/mkdir -p "$PWD/build"

# Remove plists that will not be in build (if identifier was changed)
/usr/bin/find "$PWD" -name "*.plist" -maxdepth 1 -mindepth 1 -not -name "$identifier*" -delete &> /dev/null

# Create/modify the LaunchAgent plist
[[ -e "$PWD/$daemonFileName" ]] && /usr/libexec/PlistBuddy -c Clear "$PWD/$daemonFileName" &> /dev/null
/usr/bin/defaults write "$PWD/$daemonFileName" Label -string "$identifier"
/usr/libexec/PlistBuddy -c "Add :ProgramArguments array" "$PWD/$daemonFileName"
/usr/bin/plutil -insert ProgramArguments.0 -string "/bin/bash" "$PWD/$daemonFileName"
/usr/bin/plutil -insert ProgramArguments.1 -string "/Library/Scripts/post-macos-upgrade-recon.sh" "$PWD/$daemonFileName"
/usr/bin/defaults write "$PWD/$daemonFileName" RunAtLoad -bool true
/usr/bin/defaults write "$PWD/$daemonFileName" StandardOutPath '/var/log/post-macos-upgrade-recon.log'
/usr/bin/defaults write "$PWD/$daemonFileName" StandardErrorPath '/var/log/post-macos-upgrade-recon.log'

# Migrate postinstall script to temp build directory
/bin/cp "$PWD/postinstall.sh" /private/tmp/post-macos-upgrade-recon/scripts/postinstall
/bin/chmod +x /private/tmp/post-macos-upgrade-recon/scripts/postinstall

# Put the main script in place
/bin/cp "$PWD/post-macos-upgrade-recon.sh" /private/tmp/post-macos-upgrade-recon/files/Library/Scripts/post-macos-upgrade-recon.sh

# Copy the LaunchAgent plist to the temp build directory
/bin/cp "$PWD/$daemonFileName" "/private/tmp/post-macos-upgrade-recon/files/Library/LaunchDaemons/"

# Remove any unwanted .DS_Store files from the temp build directory
/usr/bin/find "/private/tmp/post-macos-upgrade-recon/" -name '*.DS_Store' -type f -delete

# Remove the default plists if the identifier has changed
if [[ ! "$identifier" = "com.alectrona.post-macos-upgrade-recon" ]]; then
    /bin/rm "$PWD/com.alectrona.post-macos-upgrade-recon.plist" &> /dev/null
    /bin/rm "$PWD/com.alectrona.post-macos-upgrade-recon.plist" &> /dev/null
fi

# Remove any extended attributes (ACEs) from the temp build directory
/usr/bin/xattr -rc "/private/tmp/post-macos-upgrade-recon"

echo "Building the .pkg in $PWD/build/"
/usr/bin/pkgbuild --quiet --root "/private/tmp/post-macos-upgrade-recon/files/" \
    --install-location "/" \
    --scripts "/private/tmp/post-macos-upgrade-recon/scripts/" \
    --identifier "$identifier" \
    --version "$version" \
    --ownership recommended \
    "$PWD/build/Post-macOS-Upgrade-Recon_${version}.pkg"

# shellcheck disable=SC2181
if [[ "$?" == "0" ]]; then
    echo "Revealing Post-macOS-Upgrade-Recon_${version}.pkg in Finder"
    /usr/bin/open -R "$PWD/build/Post-macOS-Upgrade-Recon_${version}.pkg"
else
    echo "Build failed."
fi
exit 0