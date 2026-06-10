#!/usr/bin/env bash

if [ -z "$1" ]; then
  echo "Error: A file name must be set, e.g. \"the wonderful thing about tiggers\"."
  exit 1
fi

formatted_file_name="${1}.md"
cd "/home/adam/notes" || exit
touch "00 - Inbox/${formatted_file_name}"
nvim "00 - Inbox/${formatted_file_name}"
