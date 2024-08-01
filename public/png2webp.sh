#!/bin/bash

# Check if the required command is available
if ! command -v cwebp &> /dev/null; then
    echo "cwebp command not found. Please install it with 'sudo pacman -S libwebp'."
    exit 1
fi

# Function to convert PNG to WEBP and delete the original PNG if successful
convert_and_delete() {
    local input_file="$1"
    local output_file="${input_file%.png}.webp"

    cwebp "$input_file" -o "$output_file"
    if [[ $? -eq 0 ]]; then
        echo "Converted $input_file to $output_file"
        rm "$input_file"
        echo "Deleted original file $input_file"
    else
        echo "Failed to convert $input_file"
    fi
}

# Scan for PNG files and convert them
scan_and_convert() {
    local folder="$1"

    find "$folder" -type f -name "*.png" | while read -r png_file; do
        convert_and_delete "$png_file"
    done
}

# Main script logic
main() {
    local current_dir=$(pwd)
    scan_and_convert "$current_dir"
}

# Execute the main function
main
