#!/bin/bash
# Check if Rust server update is available without installing it

STEAMCMD="/home/rust/steamcmd/steamcmd.sh"
APPID=258550
SERVER_DIR="/home/rust/rust_server/rust_files"

# get remote buildid from Steam
REMOTE_BUILDID=$($STEAMCMD +login anonymous +app_info_print $APPID +quit \
  | awk -F'"' '/"buildid"/{print $4; exit}')

# get local buildid from installed app
LOCAL_BUILDID=$(awk -F'"' '/"buildid"/{print $4; exit}' \
  "$SERVER_DIR/steamapps/appmanifest_${APPID}.acf" 2>/dev/null)

if [ -z "$LOCAL_BUILDID" ]; then
  echo "Rust server is not installed or appmanifest not found"
  exit 2
fi

if [ "$REMOTE_BUILDID" != "$LOCAL_BUILDID" ]; then
  echo "UPDATE AVAILABLE"
  echo "Remote buildid: $REMOTE_BUILDID"
  echo "Local buildid:  $LOCAL_BUILDID"
  exit 0
else
  echo "Server is up to date"
  exit 1
fi
