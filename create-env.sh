#!/bin/bash

# Define the URL of the pack.toml
pack_url="https://<YOUR_PACKWIZ_HOST>/pack.toml"  # Replace with the actual URL

# Fetch the pack.toml
echo "Fetching pack.toml from $pack_url"
curl -s $pack_url -o pack.toml

# Extract variables from pack.toml
name=$(grep -E '^name\s*=' pack.toml | awk -F'=' '{print $2}' | tr -d ' "')
pack_format=$(grep -E '^pack-format\s*=' pack.toml | awk -F'=' '{print $2}' | tr -d ' "')
author=$(grep -E '^author\s*=' pack.toml | awk -F'=' '{print $2}' | tr -d ' "')
description=$(grep -E '^description\s*=' pack.toml | awk -F'=' '{print $2}' | tr -d ' "')
version=$(grep -E '^version\s*=' pack.toml | awk -F'=' '{print $2}' | tr -d ' "')
minecraft_version=$(grep -E '^minecraft\s*=' pack.toml | awk -F'=' '{print $2}' | tr -d ' "')
fabric_version=$(grep -E '^fabric\s*=' pack.toml | awk -F'=' '{print $2}' | tr -d ' "')
forge_version=$(grep -E '^forge\s*=' pack.toml | awk -F'=' '{print $2}' | tr -d ' "')
liteloader_version=$(grep -E '^liteloader\s*=' pack.toml | awk -F'=' '{print $2}' | tr -d ' "')
quilt_version=$(grep -E '^quilt\s*=' pack.toml | awk -F'=' '{print $2}' | tr -d ' "')

# Create the .env file
echo "Creating .env file..."
{
  echo "PACKWIZ_URL=$pack_url"
  echo "MEMORY=6G"
  echo "EULA=TRUE"
  [[ -n "$minecraft_version" ]] && echo "VERSION=$minecraft_version"
  [[ -n "$fabric_version" ]] && echo "TYPE=FABRIC" && echo "FABRIC_LAUNCHER_VERSION=$fabric_version" && echo "FABRIC_LOADER_VERSION=$fabric_version"
  [[ -n "$forge_version" ]] && echo "TYPE=FORGE" && echo "FORGE_VERSION=$forge_version"
  [[ -n "$quilt_version" ]] && echo "TYPE=QUILT" && echo "QUILT_LAUNCHER_VERSION=$quilt_version" && echo "QUILT_LOADER_VERSION=$quilt_version"
} > .env

echo ".env file created successfully!"
echo "Run 'docker compose up -d' to start"
echo "Don't be surprised if it takes a while, it has to download mods and either generate or load your world."
echo "You can always check the container's logs with 'docker logs --follow <mc_container_name>'"