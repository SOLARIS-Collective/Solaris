#!/bin/bash
set -e
source dependencies.sh
echo "Downloading BYOND version $BYOND_MAJOR.$BYOND_MINOR"

# Try downloading from the main source
echo "Attempting to download BYOND version $BYOND_MAJOR.${BYOND_MINOR}_byond.zip"
if ! curl -f --connect-timeout 10 --max-time 30 "http://www.byond.com/download/build/$BYOND_MAJOR/$BYOND_MAJOR.${BYOND_MINOR}_byond.zip" -o C:/byond.zip -A "PentestSS13/1.0 Continuous Integration"; then
    echo "BYOND download failed. The main source is offline. Checking for local backup..."
    local_backup="tools/backup/$BYOND_MAJOR.${BYOND_MINOR}_byond.zip"
    echo "Looking for local backup file: $local_backup"
    if [ -f "$local_backup" ]; then
        echo "Local backup file found. Using $local_backup."
        cp "$local_backup" C:/byond.zip
    else
        # Fallback to known legacy backup file
        legacy_backup="tools/backup/516.1685_byond.zip"
        echo "Unable to locate local backup file. Using Fallback Version. $legacy_backup"
        if [ -f "$legacy_backup" ]; then
            echo "Using Fallback Version."
            echo "NOTICE: If you're seeing this then you need to update the correct backup file."
            echo "Please download the BYOND version $BYOND_MAJOR.$BYOND_MINOR manually from http://www.byond.com/download/build/$BYOND_MAJOR/$BYOND_MAJOR.${BYOND_MINOR}_byond.zip and place it in tools/backup/"
            cp "$legacy_backup" C:/byond.zip
        else
            echo "WARNING: No local or legacy backup found. Exiting."
            echo "Please download the BYOND version $BYOND_MAJOR.$BYOND_MINOR manually from http://www.byond.com/download/build/$BYOND_MAJOR/$BYOND_MAJOR.${BYOND_MINOR}_byond.zip and place it in tools/backup/"
            exit 1
        fi
    fi
fi
