#!/bin/bash

# Check for figlet and fuse2, install if missing
if ! command -v figlet &> /dev/null || ! pacman -Q fuse2 &> /dev/null; then
    echo "Installing figlet and fuse2 if missing..."
    sudo pacman -S --noconfirm figlet fuse2
fi

clear
figlet "DaVinci Resolve"
echo "Welcome to the DaVinci Resolve Installer for Arch Linux!"
echo "=========================================================="
echo
# Prompt for version selection
echo "Which version of DaVinci Resolve would you like to install $USER ?"
echo
echo "1) DaVinci Resolve (Free/Limited)"
echo "2) DaVinci Resolve Studio (Commercial)"
echo
read -rp "Enter 1 or 2, ctrl+c to exit : " VERSION_CHOICE
echo
if [[ "$VERSION_CHOICE" == "1" ]]; then
    DOWNLOAD_URL="https://dvr.xerolinux.xyz/DaVinci_Resolve_20.0.1_Linux.zip"
    ZIP_FILE="DaVinci.zip"
elif [[ "$VERSION_CHOICE" == "2" ]]; then
    DOWNLOAD_URL="https://dvr.xerolinux.xyz/DaVinci_Resolve_Studio_20.0.1_Linux.zip"
    ZIP_FILE="DaVinciStudio.zip"
else
    echo "Invalid selection. Exiting."
    exit 1
fi

DEST_DIR="$HOME/DaVinci"

# Create directory if not exists
mkdir -p "$DEST_DIR"
cd "$DEST_DIR" || { echo "Failed to access $DEST_DIR"; exit 1; }

# Download the installer if not already present
if [[ -f "$ZIP_FILE" ]]; then
    echo "$ZIP_FILE already exists. Skipping download."
else
    echo "Downloading selected version to ~/DaVinci/..."
    echo
    curl --progress-bar -L "$DOWNLOAD_URL" -o "$ZIP_FILE"
fi

echo
# Extract the zip file
echo "Extracting files..."
echo
unzip -o "$ZIP_FILE"
echo

# Run the installer
echo "Running the DaVinci Resolve installer..."
cd "$DEST_DIR" || exit

RUN_FILE=$(find . -maxdepth 1 -name "*.run" | head -n 1)
if [[ -z "$RUN_FILE" ]]; then
    echo "No .run installer found. Exiting."
    exit 1
fi

chmod u+x "$RUN_FILE"
SKIP_PACKAGE_CHECK=1 "$RUN_FILE" && wait
INSTALL_EXIT_CODE=$?

if [[ $INSTALL_EXIT_CODE -ne 0 ]]; then
    echo "Installer exited with code $INSTALL_EXIT_CODE. Exiting."
    exit $INSTALL_EXIT_CODE
fi

# Ask for GPU type
read -rp "Are you using an NVIDIA or AMD GPU? (nvidia/amd): " GPU_TYPE
GPU_TYPE=$(echo "$GPU_TYPE" | tr '[:upper:]' '[:lower:]')

if [[ "$GPU_TYPE" == "nvidia" ]]; then
    echo
    echo "Installing CUDA support for NVIDIA..."
    sudo pacman -S --needed --noconfirm cuda
elif [[ "$GPU_TYPE" == "amd" ]]; then
    echo
    echo "Installing OpenCL support for AMD..."
    sudo pacman -S --needed apr apr-util libxcrypt-compat rocm-opencl-runtime rocm-hip-runtime
else
    echo "Unknown GPU type. Exiting."
    exit 1
fi

# Install common dependencies for both GPU types
echo
echo "Installing common dependencies..."
sudo pacman -S --needed --noconfirm \
    glu gtk2 libpng12 \
    qt5-x11extras qt5-svg qt5-webengine qt5-websockets \
    qt5-quickcontrols2 qt5-multimedia libxcrypt-compat \
    xmlsec java-runtime ffmpeg4.4 gst-plugins-bad-libs \
    python-numpy tbb luajit libc++ libc++abi

# Move conflicting libraries
echo "Disabling conflicting system libraries in Resolve's directory..."
cd /opt/resolve/libs || { echo "Failed to access /opt/resolve/libs"; exit 1; }
sudo mkdir -p disabled-libraries
sudo mv libglib* libgio* libgmodule* disabled-libraries/
echo
echo "Installation complete! You can now launch DaVinci Resolve."
rm -rf ~/DaVinci/
sleep 6
