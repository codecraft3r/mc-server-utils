#!/bin/bash

# Script to convert a modrinth .mrpack file to packwiz. (Written by myself in GO, converted to shell script GPT-4o)

# Function to extract URLs from a .mrpack file
extract_urls_from_mrpack() {
  local mrpack_file="$1"
  local temp_dir=$(mktemp -d)
  local urls=()

  # Ensure the temporary directory is cleaned up on exit
  trap 'rm -rf "$temp_dir"' EXIT

  unzip -q "$mrpack_file" -d "$temp_dir"

  # Check if the overrides directory exists and echo its contents
  if [[ -d "$temp_dir/overrides" ]]; then
    echo "Overrides directory found. Contents:"
    find "$temp_dir/overrides" -type f
  else
    echo "No overrides directory found."
  fi

  if [[ -f "$temp_dir/modrinth.index.json" ]]; then
    sha512_hashes=$(jq -r '.files[].hashes.sha512' "$temp_dir/modrinth.index.json")
    
    # Prepare JSON request body
    json_data=$(jq -n --argjson hashes "$(jq -nc '$sha512_hashes|split("\n")|map(select(. != ""))')" \
      '{hashes: $hashes, algorithm: "sha512"}')

    # Send the request to the Modrinth API
    response=$(curl -s -X POST -H "Content-Type: application/json" \
      -d "$json_data" "https://api.modrinth.com/v2/version_files")

    # Extract URLs from the response
    urls=($(echo "$response" | jq -r '.[] | "https://modrinth.com/mod/\(.project_id)/version/\(.id)"'))
  fi
  
  echo "${urls[@]}"
}

# Main function to convert .mrpack to packwiz modpack
mrpack_to_packwiz() {
  if [[ -z "$1" ]]; then
    echo "mrpack-to-packwiz requires a .mrpack file as an argument"
    exit 1
  fi

  # Check if packwiz is installed
  if ! command -v packwiz &> /dev/null; then
    echo "packwiz is either not installed or not on PATH. Ensure it is installed and on your PATH and try again."
    exit 1
  fi

  # Check if we're in a packwiz pack directory
  if ! packwiz list &> /dev/null; then
    echo "You are not in a pack directory. Run 'packwiz init', or switch to the correct directory."
    exit 1
  fi

  mrpack_file="$1"

  # Extract URLs from the .mrpack file and handle the overrides directory
  urls=$(extract_urls_from_mrpack "$mrpack_file")
  if [[ -z "$urls" ]]; then
    echo "No URLs extracted. Exiting."
    exit 1
  fi

  # Install each mod using packwiz
  for url in $urls; do
    echo "Installing $url"
    packwiz modrinth install "$url" -y
    if [[ $? -ne 0 ]]; then
      echo "Failed to install $url"
    else
      echo "Succeeded."
    fi
  done

  echo "Done."
}

mrpack_to_packwiz "$@"