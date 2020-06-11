# post-macos-upgrade-recon

A LaunchDaemon that simply performs a Jamf Pro inventory update when a change in macOS version is detected.

This is a relatively simple LaunchDaemon that performs the following when the LaunchDaemon is loaded (typically at boot):
1. Checks for network connectivity before moving on
2. Determines the macOS version and writes that to a tracking plist (the first time it runs)
3. If at any subsequent boot ups the macOS version changes (following a macOS upgrade), the daemon will perform a Jamf Pro inventory update (recon)
4. If the recon is successful, it will update the tracking plist so that the process can repeat itself after any other macOS upgrades

Notes:
 - By default logs are stored in `/var/log/post-macos-upgrade-recon.log`
 - By default the macOS version tracking plist is `/Library/Preferences/com.alectrona.configuration.plist`

## Install a release .pkg
The easiest method to use this is to grab the [latest release](https://github.com/alectrona/post-macos-upgrade-recon/releases/latest) to download a pre-built .pkg that can be deployed to your fleet; its that simple.

## Build the project into a .pkg
If you want to customize this project, you can change things like the identifier or anything else and build your own .pkg.

To build new versions you can simply run the build.sh script and specify a version number for the .pkg. The resulting .pkg will include the LaunchDaemon and target script as well as postinstall script. If you do not include a version number as a parameter then version 1.0 will be assigned as the default.

```bash
# Clone the repository and traverse into the project directory
$ git clone https://github.com/alectrona/post-macos-upgrade-recon.git
$ cd post-macos-upgrade-recon

# Build the project
$ ./build.sh 1.1
Version set to 1.1
Building the .pkg in /Users/samsonite/post-macos-upgrade-recon/build/
Revealing Post-macOS-Upgrade-Recon_1.1.pkg in Finder
```

If you customize this and build your own .pkg, remember to test!