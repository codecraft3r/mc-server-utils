#!/bin/bash

# Script to push changes to git. (Written by myself in GO, converted to shell script GPT-4o)
# This is needed as otherwise "removed" files sometimes stick around, for some reason.
push_update() {
  update_message="$1"

  if [[ -z "$update_message" ]]; then
    echo "Error: push-update requires an commit message as an argument"
    exit 1
  fi

  # Disable Git terminal prompts
  export GIT_TERMINAL_PROMPT=0

  # Remove all cached files from the Git index
  git rm -r --cached "*"
  if [[ $? -ne 0 ]]; then
    echo "Error: Failed to remove cached files"
    exit 1
  fi

  # Add all files to the Git index
  git add "*"
  if [[ $? -ne 0 ]]; then
    echo "Error: Failed to add files to Git"
    exit 1
  fi

  # Commit the changes with the provided update message
  git commit -m "$update_message"
  if [[ $? -ne 0 ]]; then
    echo "Error: Failed to commit changes"
    exit 1
  fi

  # Push the changes to the main branch
  git push origin main
  if [[ $? -ne 0 ]]; then
    echo "Error: Failed to push changes to the main branch"
    exit 1
  else
    echo "Pushed changes to main."
  fi
}

push_update "$@"