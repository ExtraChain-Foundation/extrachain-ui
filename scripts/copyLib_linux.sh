#!/bin/bash

# Directory to copy files to
destination_dir="./libForCopy"

# Check if the destination directory exists, and create it if it doesn't
if [ ! -d "$destination_dir" ]; then
    mkdir -p "$destination_dir"
fi

# Command to run ldd and capture its output
ldd_output=$(ldd ./RaccoonLine)

# Regex pattern to extract file paths (considering paths might contain spaces or special characters)
regex='=> ([^ ]+)'

# Loop through each line of ldd output
while IFS= read -r line; do
    # Check if the line contains a file path
    if [[ $line =~ $regex ]]; then
        # Extract the file path
        file_path="${BASH_REMATCH[1]}"
        
        # Copy the file to the destination directory
        cp "$file_path" "$destination_dir/"
    fi
done <<< "$ldd_output"

echo "All files have been copied to $destination_dir."
