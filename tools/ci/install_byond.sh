#!/bin/bash
set -euo pipefail

# Determine the script's directory
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"

# BYOND_MAJOR and BYOND_MINOR can be explicitly set, such as in alt_byond_versions.txt
if [ -z "${BYOND_MAJOR+x}" ]; then
  source dependencies.sh
fi

if [ -d "$HOME/BYOND/byond/bin" ] && grep -Fxq "${BYOND_MAJOR}.${BYOND_MINOR}" $HOME/BYOND/version.txt;
then
  echo "Using cached directory. ${BYOND_MAJOR}.${BYOND_MINOR} is already installed."
else
  echo "Setting up BYOND."
  rm -rf "$HOME/BYOND"
  mkdir -p "$HOME/BYOND"
  cd "$HOME/BYOND"

  # Try downloading from the main source
  echo "Attempting to download BYOND version $BYOND_MAJOR.${BYOND_MINOR}_byond_linux.zip"
  if ! curl -f --connect-timeout 10 --max-time 30 "http://www.byond.com/download/build/${BYOND_MAJOR}/${BYOND_MAJOR}.${BYOND_MINOR}_byond_linux.zip" -o byond.zip -A "PentestSS13/1.0 Continuous Integration"; then
    echo "BYOND download failed. The main source is offline. Checking for local backup..."
    local_backup="$SCRIPT_DIR/../backup/$BYOND_MAJOR.${BYOND_MINOR}_byond_linux.zip"
    echo "Looking for local backup file: $local_backup"
    if [ -f "$local_backup" ]; then
      echo "Local backup file found. Using $local_backup."
      cp "$local_backup" byond.zip
    else
      # Fallback to known legacy backup file
      legacy_backup="$SCRIPT_DIR/../backup/516.1663_byond_linux.zip"
      echo "Unable to locate local backup file. Using Fallback Version. $legacy_backup"
      if [ -f "$legacy_backup" ]; then
        echo "Using Fallback Version."
        echo "NOTICE: If you're seeing this then you need to update the correct backup file."
        echo "Please download the BYOND version $BYOND_MAJOR.$BYOND_MINOR manually from http://www.byond.com/download/build/$BYOND_MAJOR/$BYOND_MAJOR.${BYOND_MINOR}_byond_linux.zip and place it in tools/backup/"
        cp "$legacy_backup" byond.zip
      else
        echo "WARNING: No local or legacy backup found. Exiting."
        echo "Please download the BYOND version $BYOND_MAJOR.$BYOND_MINOR manually from http://www.byond.com/download/build/$BYOND_MAJOR/$BYOND_MAJOR.${BYOND_MINOR}_byond_linux.zip and place it in tools/backup/"
        exit 1
      fi
    fi
  fi

  unzip byond.zip
  rm byond.zip
  cd byond
  make here
  echo "$BYOND_MAJOR.$BYOND_MINOR" > "$HOME/BYOND/version.txt"
  cd ~/
fi
