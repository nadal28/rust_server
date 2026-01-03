#!/bin/bash
/home/rust/steamcmd/steamcmd.sh +force_install_dir /home/rust/rust_server/rust_files +login anonymous +app_update 258550 validate +quit
# After the command above the file runds.sh is modified, so we need to reset it
git checkout .