#!/bin/bash

identifier="com.alectrona.post-macos-upgrade-recon"
daemonPlist="/Library/LaunchDaemons/$identifier.plist"

# Set permissions on launchd daemon files
/usr/sbin/chown root:wheel "$daemonPlist"
/bin/chmod 644 "$daemonPlist"

# Stop the LaunchDaemon if it is running
if /bin/launchctl list | grep "$identifier" &> /dev/null ; then
    /bin/launchctl unload "$daemonPlist"
fi

# Load the LaunchDaemon
/bin/launchctl load "$daemonPlist"

exit 0
