#!/bin/bash
wget https://github.com/OxideMod/Oxide.Rust/releases/latest/download/Oxide.Rust-linux.zip
unzip -o -d rust_files/ Oxide.Rust-linux.zip
rm Oxide.Rust-linux.zip

wget -P rust_files/oxide/plugins/ https://umod.org/plugins/BuildingActions.cs