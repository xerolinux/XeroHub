#!/usr/bin/env bash

# Check if figlet is installed; if not, install it
if ! command -v figlet &> /dev/null; then
  echo "Figlet not found, installing it..."
  sudo pacman -S --noconfirm figlet
fi

source /etc/os-release

rerun_script="1" # Initialize a variable to control the loop

while [[ "$rerun_script" == "1" ]]; do
  if [ "$ID" != "arch" ] && [ "$ID" != "XeroLinux" ]; then
    # Display the message with color
    clear           # Clear the terminal window

    # Use figlet to create large ASCII text for the main message
    figlet -c "Invalid Distro Plz use with"

    # Set colors for "Vanilla Arch" and "XeroLinux"
    tput bold
    tput setaf 2  # Set text color to green for "Vanilla Arch"
    figlet -c "Vanilla Arch"

    tput setaf 4  # Set text color to blue for "&"
    tput bold
    figlet -c "& XeroLinux"

    # Reset all attributes
    tput sgr0

    # Wait for user to press ENTER
    read -p "Press ENTER to quit... " # Wait for user input
    rerun_script="0" # Exit loop after user presses Enter
  else
    # If the distro is compatible, exit the loop
    rerun_script="0"
  fi
done
