#!/bin/bash

currentOSVersion=$(/usr/bin/sw_vers -productVersion)
lastRecordedOSVersion=$(/usr/bin/defaults read /Library/Preferences/com.alectrona.configuration.plist OS_Version 2> /dev/null)

function initial_network_test () {
    # Include rc.common for the CheckForNetwork function
    . /etc/rc.common

    local counter=1

    echo "Waiting up to 240 minutes for an active network connection..."
    CheckForNetwork
    while [[ "${NETWORKUP}" != "-YES-" ]] && [[ $counter -ne 2880 ]]; do
        /bin/sleep 5
        NETWORKUP=
        CheckForNetwork
        ((counter++))
    done

    if [[ "${NETWORKUP}" == "-YES-" ]]; then
        echo "Network connection appears to be active; continuing."
    else
        echo "Network connection appears to be offline; exiting."
        exit 1
    fi
}

function external_dns_lookup_test () {
    local jamfPlist domainToLookup externalDNSServerIP dnsLookupResult timer

    jamfPlist="/Library/Preferences/com.jamfsoftware.jamf.plist"
    domainToLookup=$(/usr/bin/defaults read "$jamfPlist" jss_url | /usr/bin/sed s'/.$//' | /usr/bin/awk -F '/' '{print $NF}' | /usr/bin/cut -f1 -d":")
    externalDNSServerIP="8.8.8.8"
    dnsLookupResult=$(/usr/bin/dig @"$externalDNSServerIP" "$domainToLookup" 2> /dev/null | /usr/bin/grep -A1 'ANSWER SECTION' | /usr/bin/grep "$domainToLookup")
    timer="120"

    # Do an external DNS lookup on the Jamf Pro URL that this Mac reports to, if we get an answer from the external DNS server we have network
    echo "Performing external DNS lookup on $domainToLookup..."
    while [[ -z "$dnsLookupResult" ]] && [[ "$timer" -gt "0" ]]; do
        dnsLookupResult=$(dig @"$externalDNSServerIP" "$domainToLookup" 2> /dev/null | /usr/bin/grep -A1 'ANSWER SECTION' | /usr/bin/grep "$domainToLookup")
        sleep 1
        ((timer--))
    done

    if [[ -n "$dnsLookupResult" ]]; then
        echo "DNS lookup succeeded; continuing."
    else
        echo "DNS lookup failed; exiting."
        exit 1
    fi
}

# Run our functions to make sure we can access the Jamf Pro server
initial_network_test
external_dns_lookup_test

# If we have recorded the OS version before, check to see if our recorded value matches the current version
if [[ -n "$lastRecordedOSVersion" ]]; then
    if [[ ! "$currentOSVersion" == "$lastRecordedOSVersion" ]]; then
        echo "This Mac has been updated from $lastRecordedOSVersion to $currentOSVersion; running recon."
        if /usr/local/bin/jamf recon; then
            # Record the current OS version to use as comparison upon next run
            /usr/bin/defaults write /Library/Preferences/com.alectrona.configuration.plist OS_Version "$currentOSVersion"
        fi
    else
        echo "No change in macOS version detected."
    fi
else
    echo "This appears to be the first run; initializing plist."
    # Record the current OS version to use as comparison upon next run
    /usr/bin/defaults write /Library/Preferences/com.alectrona.configuration.plist OS_Version "$currentOSVersion"
fi

exit 0