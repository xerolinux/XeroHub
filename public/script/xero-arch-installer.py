#!/usr/bin/env python3
"""
XeroLinux Arch Installer
Complete Arch Linux Installation with KDE Plasma
"""

import os
import sys
import subprocess
import time
import shutil
import getpass

class Colors:
    RED = '\033[0;31m'
    GREEN = '\033[0;32m'
    YELLOW = '\033[1;33m'
    BLUE = '\033[0;34m'
    PURPLE = '\033[0;35m'
    CYAN = '\033[0;36m'
    NC = '\033[0m'

class Installer:
    def __init__(self):
        self.install_device = ""
        self.efi_partition = ""
        self.root_partition = ""
        self.hostname = ""
        self.username = ""
        self.timezone = ""
        self.locale = ""
        self.keymap = ""
        self.is_uefi = False
        self.filesystem = ""
        self.use_encryption = False
        self.luks_password = ""
        # GPU detection
        self.detected_gpus = []
        self.gpu_packages = []
        self.has_intel = False
        self.has_amd = False
        self.has_nvidia = False
        self.nvidia_type = None  # "modern" or "legacy"
        self.is_vm = False
        self.is_admin = True
        
    def run_command(self, cmd, check=True, shell=True, capture_output=False):
        try:
            if capture_output:
                result = subprocess.run(cmd, shell=shell, check=check, 
                                       capture_output=True, text=True)
                return result.stdout.strip()
            else:
                subprocess.run(cmd, shell=shell, check=check)
                return True
        except subprocess.CalledProcessError:
            if check:
                return False
            return False
    
    def print_header(self):
        os.system('clear')
        print(f"{Colors.PURPLE}╔════════════════════════════════════════════════╗{Colors.NC}")
        print(f"{Colors.PURPLE}║                                                ║{Colors.NC}")
        print(f"{Colors.PURPLE}║{Colors.CYAN}        XeroLinux Arch Installer v2.0          {Colors.PURPLE}║{Colors.NC}")
        print(f"{Colors.PURPLE}║                                                ║{Colors.NC}")
        print(f"{Colors.PURPLE}╚════════════════════════════════════════════════╝{Colors.NC}")
        print()
    
    def print_step(self, msg):
        print(f"{Colors.BLUE}>>{Colors.NC} {Colors.CYAN}{msg}{Colors.NC}")
    
    def print_success(self, msg):
        print(f"{Colors.GREEN}[✓]{Colors.NC} {msg}")
    
    def print_error(self, msg):
        print(f"{Colors.RED}[✗]{Colors.NC} {msg}")
    
    def print_warning(self, msg):
        print(f"{Colors.YELLOW}[!]{Colors.NC} {msg}")
    
    def pause(self):
        try:
            input("Press Enter to continue...")
        except EOFError:
            time.sleep(1)
    
    def get_input(self, prompt):
        try:
            return input(prompt)
        except EOFError:
            print("\nError: Cannot read input.")
            sys.exit(1)
    
    def get_password(self, prompt):
        """Get password input with masking"""
        try:
            return getpass.getpass(prompt)
        except EOFError:
            print("\nError: Cannot read input.")
            sys.exit(1)
    
    def check_root(self):
        if os.geteuid() != 0:
            self.print_error("This installer must be run as root!")
            sys.exit(1)
    
    def check_internet(self):
        self.print_step("Checking internet connection...")
        if self.run_command("ping -c 1 archlinux.org", check=False):
            self.print_success("Internet connection active")
        else:
            self.print_error("No internet connection!")
            sys.exit(1)
    
    def check_uefi(self):
        self.print_step("Detecting boot mode...")
        if os.path.isdir("/sys/firmware/efi/efivars"):
            self.is_uefi = True
            self.print_success("UEFI mode detected")
        else:
            self.is_uefi = False
            self.print_success("BIOS mode detected")
    
    def install_dependencies(self):
        self.print_step("Installing dependencies...")
        self.run_command("pacman -Sy --noconfirm", check=False)
        for tool in ["dialog", "fzf", "gum", "git"]:
            if not shutil.which(tool):
                self.run_command(f"pacman -S --noconfirm {tool}", check=False)
        self.print_success("Dependencies installed")
    
    def preflight_checks(self):
        self.print_header()
        print(f"{Colors.CYAN}Pre-flight checks...{Colors.NC}\n")
        self.check_root()
        self.check_internet()
        self.check_uefi()
        self.install_dependencies()
        print()
        self.print_success("All checks passed!")
        print()
        self.pause()
    
    def select_disk(self):
        self.print_header()
        print(f"{Colors.CYAN}[Step 1/12] Select Disk{Colors.NC}\n")
        print(f"{Colors.YELLOW}[!] WARNING: All data will be ERASED!{Colors.NC}\n")
        
        disks = self.run_command("lsblk -ndo NAME,SIZE,TYPE | grep disk", 
                                 capture_output=True).split('\n')
        disk_list = []
        for i, disk in enumerate(disks, 1):
            parts = disk.split()
            if parts:
                name = parts[0]
                size = parts[1] if len(parts) > 1 else "Unknown"
                print(f"  {Colors.BLUE}{i}){Colors.NC} /dev/{name} - {size}")
                disk_list.append(name)
        
        print()
        choice = self.get_input("Enter disk number: ")
        
        try:
            choice = int(choice)
            if 1 <= choice <= len(disk_list):
                self.install_device = f"/dev/{disk_list[choice-1]}"
                print()
                print(f"{Colors.RED}╔════════════════════════════════════════════════╗{Colors.NC}")
                print(f"{Colors.RED}║              FINAL WARNING                     ║{Colors.NC}")
                print(f"{Colors.RED}╠════════════════════════════════════════════════╣{Colors.NC}")
                print(f"{Colors.RED}║{Colors.NC}  Selected: {Colors.YELLOW}{self.install_device:<33}{Colors.NC}{Colors.RED}║{Colors.NC}")
                print(f"{Colors.RED}║{Colors.NC}  ALL DATA WILL BE ERASED!                     {Colors.RED}║{Colors.NC}")
                print(f"{Colors.RED}╚════════════════════════════════════════════════╝{Colors.NC}")
                print()
                
                confirm = self.get_input("Type 'YES' to confirm: ")
                if confirm == "YES":
                    self.print_success(f"Disk {self.install_device} selected")
                else:
                    sys.exit(1)
            else:
                sys.exit(1)
        except ValueError:
            sys.exit(1)
    
    def detect_gpu(self):
        """Auto-detect GPU hardware and select appropriate drivers"""
        self.print_header()
        print(f"{Colors.CYAN}[Step 2/12] GPU Detection{Colors.NC}\n")
        self.print_step("Scanning hardware...")
        print()
        
        # Reset GPU tracking
        self.detected_gpus = []
        self.gpu_packages = []
        self.has_intel = False
        self.has_amd = False
        self.has_nvidia = False
        self.nvidia_type = None  # "modern" or "legacy"
        self.is_vm = False
        
        # Get GPU info from lspci
        lspci_output = self.run_command("lspci -nn | grep -E 'VGA|3D|Display'", capture_output=True)
        
        if not lspci_output:
            self.print_warning("No GPU detected - using basic drivers")
            self.is_vm = True
            self.pause()
            return
        
        gpu_lines = lspci_output.strip().split('\n')
        
        # Check for VM - multiple detection methods
        vm_indicators = [
            "virtio", "vmware", "qxl", "bochs", "virtualbox", 
            "hyper-v", "parallels", "vbox", "vesa", "cirrus",
            "red hat", "qemu", "spice", "llvmpipe"
        ]
        
        # Method 1: Check lspci output
        for line in gpu_lines:
            line_lower = line.lower()
            if any(vm in line_lower for vm in vm_indicators):
                self.print_warning("Virtual machine detected")
                self.is_vm = True
                print(f"  {Colors.YELLOW}→{Colors.NC} Skipping proprietary GPU drivers")
                print()
                self.pause()
                return
        
        # Method 2: Check systemd-detect-virt
        virt_check = self.run_command("systemd-detect-virt", capture_output=True, check=False)
        if virt_check and virt_check != "none":
            self.print_warning(f"Virtual machine detected ({virt_check})")
            self.is_vm = True
            print(f"  {Colors.YELLOW}→{Colors.NC} Skipping proprietary GPU drivers")
            print()
            self.pause()
            return
        
        # Method 3: Check for hypervisor in /proc/cpuinfo
        try:
            with open("/proc/cpuinfo", "r") as f:
                cpuinfo = f.read().lower()
                if "hypervisor" in cpuinfo:
                    self.print_warning("Virtual machine detected (hypervisor flag)")
                    self.is_vm = True
                    print(f"  {Colors.YELLOW}→{Colors.NC} Skipping proprietary GPU drivers")
                    print()
                    self.pause()
                    return
        except:
            pass
        
        # Detect Intel
        for line in gpu_lines:
            if "intel" in line.lower():
                self.has_intel = True
                # Extract GPU name
                gpu_name = self._extract_gpu_name(line, "Intel")
                self.detected_gpus.append(f"Intel {gpu_name}")
                self.print_success(f"Detected: Intel {gpu_name}")
        
        # Detect AMD
        for line in gpu_lines:
            line_lower = line.lower()
            if "amd" in line_lower or "radeon" in line_lower or "ati" in line_lower:
                self.has_amd = True
                gpu_name = self._extract_gpu_name(line, "AMD")
                self.detected_gpus.append(f"AMD {gpu_name}")
                self.print_success(f"Detected: AMD {gpu_name}")
        
        # Detect NVIDIA and determine generation
        for line in gpu_lines:
            if "nvidia" in line.lower():
                self.has_nvidia = True
                gpu_name = self._extract_gpu_name(line, "NVIDIA")
                nvidia_gen = self._detect_nvidia_generation(line, gpu_name)
                self.nvidia_type = nvidia_gen
                gen_label = "Turing+" if nvidia_gen == "modern" else "Legacy"
                self.detected_gpus.append(f"NVIDIA {gpu_name} ({gen_label})")
                self.print_success(f"Detected: NVIDIA {gpu_name} ({gen_label})")
        
        # If nothing detected
        if not (self.has_intel or self.has_amd or self.has_nvidia):
            self.print_warning("No supported GPU detected - using basic drivers")
            print()
            self.pause()
            return
        
        # Build package list
        print()
        self._build_gpu_packages()
        
        # Show what will be installed
        print(f"{Colors.CYAN}The following drivers will be installed:{Colors.NC}")
        if self.has_intel:
            print(f"  {Colors.BLUE}•{Colors.NC} Intel: intel-drv (meta package)")
        if self.has_amd:
            print(f"  {Colors.BLUE}•{Colors.NC} AMD: amd-drv (meta package)")
        if self.has_nvidia:
            if self.nvidia_type == "modern":
                print(f"  {Colors.BLUE}•{Colors.NC} NVIDIA (Turing+): nvidia-open-dkms, nvidia-utils, etc.")
            else:
                print(f"  {Colors.BLUE}•{Colors.NC} NVIDIA (Legacy): nvidia-580xx-dkms, nvidia-580xx-utils, etc.")
        
        # Optimus detection
        if self.has_intel and self.has_nvidia:
            print()
            print(f"{Colors.YELLOW}[!]{Colors.NC} Optimus laptop detected (Intel + NVIDIA)")
            print(f"    EnvyControl will be installed for GPU switching")
            self.gpu_packages.append("envycontrol")
        
        print()
        confirm = self.get_input("Proceed with these drivers? [Y/n]: ")
        if confirm.lower() == 'n':
            self._manual_gpu_override()
        
        print()
        self.pause()
    
    def _extract_gpu_name(self, lspci_line, vendor):
        """Extract GPU model name from lspci output"""
        try:
            # Try to get the part after the vendor name in brackets
            if "[" in lspci_line and "]" in lspci_line:
                # Find the description part
                parts = lspci_line.split(": ", 1)
                if len(parts) > 1:
                    desc = parts[1]
                    # Remove the PCI ID at the end [xxxx:xxxx]
                    if desc.count("[") >= 2:
                        desc = desc.rsplit("[", 1)[0].strip()
                    # Remove vendor prefix
                    for prefix in ["Intel Corporation ", "NVIDIA Corporation ", "Advanced Micro Devices, Inc. ", "AMD/ATI "]:
                        desc = desc.replace(prefix, "")
                    return desc.strip()
            return "Graphics"
        except:
            return "Graphics"
    
    def _detect_nvidia_generation(self, lspci_line, gpu_name):
        """Determine if NVIDIA GPU is Turing+ or Legacy"""
        line_lower = lspci_line.lower() + gpu_name.lower()
        
        # Turing+ indicators (RTX series, 1650, 1660, 20/30/40/50 series)
        turing_plus = [
            "rtx", "1650", "1660",  # Turing
            "2060", "2070", "2080",  # Turing
            "3050", "3060", "3070", "3080", "3090",  # Ampere
            "4060", "4070", "4080", "4090",  # Ada Lovelace
            "5070", "5080", "5090",  # Blackwell
            "a2000", "a3000", "a4000", "a5000", "a6000",  # Professional
            "tu1", "tu10", "tu11", "tu116", "tu117",  # Turing arch codes
            "ga10", "ga102", "ga103", "ga104", "ga106", "ga107",  # Ampere arch codes
            "ad10", "ad102", "ad103", "ad104", "ad106", "ad107",  # Ada arch codes
        ]
        
        # Legacy indicators (Maxwell, Pascal - 900/1000 series except 1650/1660)
        legacy = [
            "gtx 9", "gtx9",  # Maxwell (900 series)
            "gtx 10", "gtx10",  # Pascal (1000 series)
            "gt 10", "gt10",
            "gm1", "gm2",  # Maxwell arch codes
            "gp10", "gp102", "gp104", "gp106", "gp107", "gp108",  # Pascal arch codes
            "quadro m", "quadro p",  # Professional Maxwell/Pascal
        ]
        
        # Check for Turing+ first (higher priority)
        for indicator in turing_plus:
            if indicator in line_lower:
                return "modern"
        
        # Check for Legacy
        for indicator in legacy:
            if indicator in line_lower:
                return "legacy"
        
        # Default to modern for unknown (safer for newer cards)
        return "modern"
    
    def _build_gpu_packages(self):
        """Build the list of GPU packages to install"""
        self.gpu_packages = []
        
        if self.has_intel:
            self.gpu_packages.extend(["intel-drv", "linux-firmware-intel"])
        
        if self.has_amd:
            self.gpu_packages.extend(["amd-drv", "linux-firmware-amd", "linux-firmware-radeon"])
        
        if self.has_nvidia:
            # linux-firmware-nvidia needed for all NVIDIA (nouveau fallback too)
            self.gpu_packages.append("linux-firmware-nvidia")
            
            if self.nvidia_type == "modern":
                self.gpu_packages.extend([
                    "nvidia-open-dkms",
                    "nvidia-utils",
                    "lib32-nvidia-utils",
                    "nvidia-settings",
                    "opencl-nvidia",
                    "lib32-opencl-nvidia",
                    "libvdpau",
                    "libvdpau-va-gl",
                    "vulkan-icd-loader",
                    "lib32-vulkan-icd-loader"
                ])
            else:  # legacy
                self.gpu_packages.extend([
                    "nvidia-580xx-dkms",
                    "nvidia-580xx-utils",
                    "lib32-nvidia-580xx-utils",
                    "opencl-nvidia-580xx",
                    "lib32-opencl-nvidia-580xx"
                ])
    
    def _manual_gpu_override(self):
        """Allow manual GPU selection if auto-detect is wrong"""
        self.print_header()
        print(f"{Colors.CYAN}Manual GPU Selection{Colors.NC}\n")
        print("Select your GPU configuration:")
        print(f"  {Colors.BLUE}1){Colors.NC} Intel only")
        print(f"  {Colors.BLUE}2){Colors.NC} AMD only")
        print(f"  {Colors.BLUE}3){Colors.NC} NVIDIA Turing+ (RTX/1650/1660/20/30/40/50 series)")
        print(f"  {Colors.BLUE}4){Colors.NC} NVIDIA Legacy (900/1000 series)")
        print(f"  {Colors.BLUE}5){Colors.NC} Intel + NVIDIA Turing+ (Optimus)")
        print(f"  {Colors.BLUE}6){Colors.NC} Intel + NVIDIA Legacy (Optimus)")
        print(f"  {Colors.BLUE}7){Colors.NC} Intel + AMD")
        print(f"  {Colors.BLUE}8){Colors.NC} AMD + NVIDIA Turing+")
        print(f"  {Colors.BLUE}9){Colors.NC} AMD + NVIDIA Legacy")
        print(f"  {Colors.BLUE}0){Colors.NC} None / Virtual Machine")
        print()
        
        choice = self.get_input("Enter choice (0-9): ")
        
        # Reset
        self.has_intel = False
        self.has_amd = False
        self.has_nvidia = False
        self.nvidia_type = None
        
        if choice == "1":
            self.has_intel = True
        elif choice == "2":
            self.has_amd = True
        elif choice == "3":
            self.has_nvidia = True
            self.nvidia_type = "modern"
        elif choice == "4":
            self.has_nvidia = True
            self.nvidia_type = "legacy"
        elif choice == "5":
            self.has_intel = True
            self.has_nvidia = True
            self.nvidia_type = "modern"
            self.gpu_packages.append("envycontrol")
        elif choice == "6":
            self.has_intel = True
            self.has_nvidia = True
            self.nvidia_type = "legacy"
            self.gpu_packages.append("envycontrol")
        elif choice == "7":
            self.has_intel = True
            self.has_amd = True
        elif choice == "8":
            self.has_amd = True
            self.has_nvidia = True
            self.nvidia_type = "modern"
        elif choice == "9":
            self.has_amd = True
            self.has_nvidia = True
            self.nvidia_type = "legacy"
        else:
            self.is_vm = True
            return
        
        self._build_gpu_packages()
        self.print_success("Manual selection applied")
    
    def configure_nvidia(self):
        """Configure NVIDIA specific settings for mkinitcpio and GRUB"""
        if not self.has_nvidia:
            return
        
        self.print_step("Configuring NVIDIA...")
        
        # Determine module names based on driver type
        if self.nvidia_type == "modern":
            modules = "nvidia nvidia_modeset nvidia_uvm nvidia_drm"
        else:  # legacy 580xx
            modules = "nvidia nvidia_modeset nvidia_uvm nvidia_drm"
        
        # Add modules to mkinitcpio.conf
        self.print_step("Adding NVIDIA modules to initramfs...")
        self.run_command(f"sed -i 's/^MODULES=(/MODULES=({modules} /' /mnt/etc/mkinitcpio.conf")
        
        # Rebuild initramfs
        self.print_step("Rebuilding initramfs...")
        self.run_command("arch-chroot /mnt mkinitcpio -P")
        
        # Add kernel parameters to GRUB
        self.print_step("Configuring GRUB for NVIDIA...")
        grub_params = "nvidia-drm.modeset=1"
        
        # Read current GRUB config
        grub_default = "/mnt/etc/default/grub"
        with open(grub_default, 'r') as f:
            grub_content = f.read()
        
        # Add nvidia params if not already present
        if "nvidia-drm.modeset=1" not in grub_content:
            grub_content = grub_content.replace(
                'GRUB_CMDLINE_LINUX_DEFAULT="',
                f'GRUB_CMDLINE_LINUX_DEFAULT="{grub_params} '
            )
            with open(grub_default, 'w') as f:
                f.write(grub_content)
        
        # Blacklist nouveau
        self.print_step("Blacklisting nouveau driver...")
        with open("/mnt/etc/modprobe.d/nvidia-blacklist.conf", "w") as f:
            f.write("blacklist nouveau\n")
            f.write("options nouveau modeset=0\n")
        
        self.print_success("NVIDIA configured")
    
    def install_gpu_drivers(self):
        """Install detected GPU drivers"""
        if not self.gpu_packages or self.is_vm:
            self.print_step("Skipping GPU drivers (VM or none selected)")
            return
        
        self.print_step("Installing GPU drivers...")
        
        # Show what's being installed
        if self.has_intel:
            self.print_step("Installing Intel drivers...")
        if self.has_amd:
            self.print_step("Installing AMD drivers...")
        if self.has_nvidia:
            driver_type = "Turing+" if self.nvidia_type == "modern" else "Legacy (580xx)"
            self.print_step(f"Installing NVIDIA {driver_type} drivers...")
        
        packages_str = " ".join(self.gpu_packages)
        result = self.run_command(f"arch-chroot /mnt pacman -S --needed --noconfirm {packages_str}", check=False)
        
        if result:
            self.print_success("GPU drivers installed")
            
            # Configure NVIDIA if present
            if self.has_nvidia:
                self.configure_nvidia()
        else:
            self.print_warning("Some GPU drivers failed to install")
    
    def select_filesystem(self):
        """Select filesystem and other configuration options"""
        self.print_header()
        print(f"{Colors.CYAN}[Step 3/12] Configuration{Colors.NC}\n")
        
        # Filesystem selection
        print("Filesystem:")
        print(f"  {Colors.BLUE}1){Colors.NC} EXT4   {Colors.BLUE}2){Colors.NC} XFS   {Colors.BLUE}3){Colors.NC} BTRFS")
        choice = self.get_input("Choice (1-3, default EXT4): ")
        
        if choice == "2":
            self.filesystem = "xfs"
        elif choice == "3":
            self.filesystem = "btrfs"
        else:
            self.filesystem = "ext4"
        
        self.print_success(f"Filesystem: {self.filesystem.upper()}")
        print()
        
        # Timezone
        print("Timezone:")
        timezones = self.run_command("timedatectl list-timezones", capture_output=True)
        process = subprocess.Popen(["fzf", "--height", "20", "--reverse"],
                                  stdin=subprocess.PIPE, stdout=subprocess.PIPE, text=True)
        self.timezone, _ = process.communicate(input=timezones)
        self.timezone = self.timezone.strip()
        if not self.timezone:
            self.timezone = "UTC"
        self.print_success(f"Timezone: {self.timezone}")
        print()
        
        # Locale
        print("Locale:")
        locales = ["en_US.UTF-8", "en_GB.UTF-8", "de_DE.UTF-8", "fr_FR.UTF-8",
                  "es_ES.UTF-8", "it_IT.UTF-8", "pt_BR.UTF-8", "ru_RU.UTF-8"]
        for i, loc in enumerate(locales, 1):
            print(f"  {Colors.BLUE}{i}){Colors.NC} {loc}")
        print(f"  {Colors.BLUE}0){Colors.NC} Search all")
        
        choice = self.get_input("Choice: ")
        if choice == "0":
            all_locales = self.run_command("cat /etc/locale.gen | grep UTF-8 | cut -d' ' -f1", capture_output=True)
            process = subprocess.Popen(["fzf", "--height", "20"],
                                      stdin=subprocess.PIPE, stdout=subprocess.PIPE, text=True)
            self.locale, _ = process.communicate(input=all_locales)
            self.locale = self.locale.strip()
        else:
            try:
                idx = int(choice)
                self.locale = locales[idx-1] if 1 <= idx <= len(locales) else "en_US.UTF-8"
            except:
                self.locale = "en_US.UTF-8"
        
        if not self.locale:
            self.locale = "en_US.UTF-8"
        self.print_success(f"Locale: {self.locale}")
        print()
        
        # Keymap
        print("Keyboard:")
        keymaps = ["us", "uk", "de", "fr", "es", "it", "br", "ru"]
        for i, km in enumerate(keymaps, 1):
            print(f"  {Colors.BLUE}{i}){Colors.NC} {km}")
        print(f"  {Colors.BLUE}0){Colors.NC} Search all")
        
        choice = self.get_input("Choice: ")
        if choice == "0":
            all_keymaps = self.run_command("localectl list-keymaps", capture_output=True)
            process = subprocess.Popen(["fzf", "--height", "20"],
                                      stdin=subprocess.PIPE, stdout=subprocess.PIPE, text=True)
            self.keymap, _ = process.communicate(input=all_keymaps)
            self.keymap = self.keymap.strip()
        else:
            try:
                idx = int(choice)
                self.keymap = keymaps[idx-1] if 1 <= idx <= len(keymaps) else "us"
            except:
                self.keymap = "us"
        
        if not self.keymap:
            self.keymap = "us"
        self.print_success(f"Keymap: {self.keymap}")
        print()
        
        # Encryption
        encrypt = self.get_input("Encrypt root partition? [y/N]: ")
        if encrypt.lower() == 'y':
            self.use_encryption = True
            while True:
                self.luks_password = self.get_password("Encryption password: ")
                confirm = self.get_password("Confirm password: ")
                if self.luks_password == confirm:
                    self.print_success("Encryption enabled")
                    break
                else:
                    self.print_error("Passwords don't match!")
        else:
            self.use_encryption = False
        
        print()
        self.pause()
    
    def partition_disk(self):
        self.print_header()
        print(f"{Colors.CYAN}[Step 4/12] Partitioning{Colors.NC}\n")
        self.print_step(f"Partitioning {self.install_device}...")
        
        self.run_command(f"wipefs -af {self.install_device}")
        self.run_command(f"sgdisk -Z {self.install_device}")
        
        if self.is_uefi:
            self.run_command(f"parted -s {self.install_device} mklabel gpt")
            self.run_command(f"parted -s {self.install_device} mkpart primary fat32 1MiB 513MiB")
            self.run_command(f"parted -s {self.install_device} set 1 esp on")
            self.run_command(f"parted -s {self.install_device} mkpart primary 513MiB 100%")
            time.sleep(2)
            
            if "nvme" in self.install_device:
                self.efi_partition = f"{self.install_device}p1"
                self.root_partition = f"{self.install_device}p2"
            else:
                self.efi_partition = f"{self.install_device}1"
                self.root_partition = f"{self.install_device}2"
            
            self.print_success("UEFI partitions created")
        else:
            self.run_command(f"parted -s {self.install_device} mklabel msdos")
            self.run_command(f"parted -s {self.install_device} mkpart primary 1MiB 100%")
            self.run_command(f"parted -s {self.install_device} set 1 boot on")
            time.sleep(2)
            
            if "nvme" in self.install_device:
                self.root_partition = f"{self.install_device}p1"
            else:
                self.root_partition = f"{self.install_device}1"
            
            self.print_success("BIOS partitions created")
        
        print()
        self.pause()
    
    def format_partitions(self):
        self.print_header()
        print(f"{Colors.CYAN}[Step 5/12] Formatting{Colors.NC}\n")
        
        if self.is_uefi:
            self.print_step("Formatting EFI...")
            self.run_command(f"mkfs.fat -F32 {self.efi_partition}")
            self.print_success("EFI formatted")
        
        # Wipe any existing filesystem signatures before encryption
        self.print_step("Wiping existing signatures...")
        self.run_command(f"wipefs -af {self.root_partition}")
        
        root_device = self.root_partition
        
        if self.use_encryption:
            self.print_step("Setting up encryption...")
            luks_cmd = f"echo -n '{self.luks_password}' | cryptsetup luksFormat --type luks2 {self.root_partition} -"
            self.run_command(luks_cmd)
            open_cmd = f"echo -n '{self.luks_password}' | cryptsetup open {self.root_partition} cryptroot -"
            self.run_command(open_cmd)
            root_device = "/dev/mapper/cryptroot"
            self.print_success("Encryption enabled")
        
        self.print_step(f"Formatting {self.filesystem.upper()}...")
        
        if self.filesystem == "ext4":
            self.run_command(f"mkfs.ext4 -F {root_device}")
        elif self.filesystem == "xfs":
            self.run_command(f"mkfs.xfs -f {root_device}")
        elif self.filesystem == "btrfs":
            self.run_command(f"mkfs.btrfs -f {root_device}")
            self.print_step("Creating subvolumes...")
            self.run_command(f"mount {root_device} /mnt")
            self.run_command("btrfs subvolume create /mnt/@")
            self.run_command("btrfs subvolume create /mnt/@home")
            self.run_command("btrfs subvolume create /mnt/@log")
            self.run_command("btrfs subvolume create /mnt/@cache")
            self.run_command("btrfs subvolume create /mnt/@snapshots")
            self.run_command("umount /mnt")
            self.print_success("Subvolumes created")
        
        self.print_success("Formatting complete")
        print()
        self.pause()
    
    def mount_partitions(self):
        self.print_header()
        print(f"{Colors.CYAN}[Step 6/12] Mounting{Colors.NC}\n")
        self.print_step("Mounting partitions...")
        
        root_device = "/dev/mapper/cryptroot" if self.use_encryption else self.root_partition
        
        if self.filesystem == "btrfs":
            opts = "noatime,compress=zstd:1,space_cache=v2,discard=async"
            self.run_command(f"mount -o {opts},subvol=@ {root_device} /mnt")
            self.run_command("mkdir -p /mnt/home /mnt/var/log /mnt/var/cache /mnt/.snapshots")
            self.run_command(f"mount -o {opts},subvol=@home {root_device} /mnt/home")
            self.run_command(f"mount -o {opts},subvol=@log {root_device} /mnt/var/log")
            self.run_command(f"mount -o {opts},subvol=@cache {root_device} /mnt/var/cache")
            self.run_command(f"mount -o {opts},subvol=@snapshots {root_device} /mnt/.snapshots")
        else:
            self.run_command(f"mount {root_device} /mnt")
        
        if self.is_uefi:
            self.run_command("mkdir -p /mnt/boot/efi")
            self.run_command(f"mount {self.efi_partition} /mnt/boot/efi")
        
        self.print_success("Partitions mounted")
        print()
        self.pause()
    
    def install_base_system(self):
        self.print_header()
        print(f"{Colors.CYAN}[Step 7/12] Base System{Colors.NC}\n")
        self.print_step("Installing base system...")
        
        packages = ["base", "base-devel", "linux", "linux-headers",
                   "networkmanager", "grub", "efibootmgr", "os-prober", "sudo",
                   "nano", "vim", "git", "wget", "curl", "gum"]
        
        if self.filesystem == "btrfs":
            packages.append("btrfs-progs")
        elif self.filesystem == "xfs":
            packages.append("xfsprogs")
        
        if self.use_encryption:
            packages.append("cryptsetup")
        
        self.run_command(f"pacstrap /mnt {' '.join(packages)}")
        self.print_success("Base system installed")
        
        self.print_step("Generating fstab...")
        self.run_command("genfstab -U /mnt >> /mnt/etc/fstab")
        
        if self.use_encryption:
            uuid = self.run_command(f"blkid -s UUID -o value {self.root_partition}", capture_output=True)
            with open("/mnt/etc/crypttab", "w") as f:
                f.write(f"cryptroot UUID={uuid} none luks\n")
            self.run_command("sed -i 's/^HOOKS=.*/HOOKS=(base udev autodetect microcode modconf kms keyboard keymap consolefont block encrypt filesystems fsck)/' /mnt/etc/mkinitcpio.conf")
        
        self.print_success("Configuration complete")
        print()
        self.pause()
    
    def configure_repos(self):
        """Configure Chaotic-AUR and XeroLinux repos in chroot"""
        self.print_header()
        print(f"{Colors.CYAN}[Step 8/12] Configuring Repositories{Colors.NC}\n")
        
        # === Chaotic-AUR ===
        self.print_step("Setting up Chaotic-AUR...")
        
        # Import and sign key
        self.run_command("arch-chroot /mnt pacman-key --recv-key 3056513887B78AEB --keyserver keyserver.ubuntu.com")
        self.run_command("arch-chroot /mnt pacman-key --lsign-key 3056513887B78AEB")
        
        # Install keyring and mirrorlist
        self.run_command("arch-chroot /mnt pacman -U --noconfirm 'https://cdn-mirror.chaotic.cx/chaotic-aur/chaotic-keyring.pkg.tar.zst'")
        self.run_command("arch-chroot /mnt pacman -U --noconfirm 'https://cdn-mirror.chaotic.cx/chaotic-aur/chaotic-mirrorlist.pkg.tar.zst'")
        
        # Add to pacman.conf
        with open("/mnt/etc/pacman.conf", "a") as f:
            f.write("\n[chaotic-aur]\nInclude = /etc/pacman.d/chaotic-mirrorlist\n")
        
        self.print_success("Chaotic-AUR configured")
        
        # === XeroLinux ===
        self.print_step("Setting up XeroLinux repo...")
        
        with open("/mnt/etc/pacman.conf", "a") as f:
            f.write("\n[xerolinux]\nSigLevel = Optional TrustAll\nServer = https://repos.xerolinux.xyz/$repo/$arch\n")
        
        self.print_success("XeroLinux repo configured")
        
        # === Sync databases ===
        self.print_step("Syncing package databases...")
        self.run_command("arch-chroot /mnt pacman -Sy")
        
        self.print_success("Repositories configured")
        print()
        self.pause()
    
    def configure_system(self):
        self.print_header()
        print(f"{Colors.CYAN}[Step 9/12] System Config{Colors.NC}\n")
        
        self.hostname = self.get_input("Hostname: ")
        with open("/mnt/etc/hostname", "w") as f:
            f.write(self.hostname)
        
        with open("/mnt/etc/hosts", "w") as f:
            f.write(f"127.0.0.1   localhost\n::1         localhost\n127.0.1.1   {self.hostname}\n")
        
        self.print_success(f"Hostname: {self.hostname}")
        
        self.print_step("Applying timezone...")
        self.run_command(f"arch-chroot /mnt ln -sf /usr/share/zoneinfo/{self.timezone} /etc/localtime")
        self.run_command("arch-chroot /mnt hwclock --systohc")
        self.print_success(f"Timezone: {self.timezone}")
        
        self.print_step("Applying locale...")
        self.run_command(f"sed -i 's/^#{self.locale}/{self.locale}/' /mnt/etc/locale.gen")
        self.run_command("arch-chroot /mnt locale-gen")
        with open("/mnt/etc/locale.conf", "w") as f:
            f.write(f"LANG={self.locale}\n")
        self.print_success(f"Locale: {self.locale}")
        
        self.print_step("Applying keymap...")
        with open("/mnt/etc/vconsole.conf", "w") as f:
            f.write(f"KEYMAP={self.keymap}\n")
        self.print_success(f"Keymap: {self.keymap}")
        
        print()
        self.pause()
    
    def configure_users(self):
        self.print_header()
        print(f"{Colors.CYAN}[Step 10/12] Users{Colors.NC}\n")
        
        while True:
            root_pass = self.get_password("Root password: ")
            confirm = self.get_password("Confirm: ")
            if root_pass == confirm:
                self.run_command(f"arch-chroot /mnt bash -c \"echo 'root:{root_pass}' | chpasswd\"")
                self.print_success("Root password set")
                break
            else:
                self.print_error("Passwords don't match!")
        
        print()
        self.username = self.get_input("Username: ")
        
        # Ask about admin privileges
        print()
        print("Grant admin (sudo) privileges?")
        print(f"  {Colors.BLUE}y){Colors.NC} Yes - User can run commands as root with sudo")
        print(f"  {Colors.BLUE}n){Colors.NC} No  - Standard user without admin access")
        admin_choice = self.get_input("Make user admin? [Y/n]: ")
        
        if admin_choice.lower() == 'n':
            # Standard user without wheel group
            self.run_command(f"arch-chroot /mnt useradd -m -G audio,video,storage -s /bin/bash {self.username}")
            self.is_admin = False
            self.print_success(f"User {self.username} will be a standard user")
        else:
            # Admin user with wheel group
            self.run_command(f"arch-chroot /mnt useradd -m -G wheel,audio,video,storage -s /bin/bash {self.username}")
            self.is_admin = True
            self.print_success(f"User {self.username} will be an administrator")
        
        print()
        while True:
            user_pass = self.get_password(f"Password for {self.username}: ")
            confirm = self.get_password("Confirm: ")
            if user_pass == confirm:
                self.run_command(f"arch-chroot /mnt bash -c \"echo '{self.username}:{user_pass}' | chpasswd\"")
                self.print_success(f"User {self.username} created")
                break
            else:
                self.print_error("Passwords don't match!")
        
        # Only enable sudo for wheel group if user is admin
        if self.is_admin:
            self.run_command("sed -i 's/^# %wheel ALL=(ALL:ALL) ALL/%wheel ALL=(ALL:ALL) ALL/' /mnt/etc/sudoers")
            self.print_success("Sudo privileges enabled")
        
        print()
        self.pause()
    
    def install_bootloader(self):
        self.print_header()
        print(f"{Colors.CYAN}[Step 11/12] Bootloader{Colors.NC}\n")
        self.print_step("Installing GRUB...")
        
        if self.is_uefi:
            self.run_command("arch-chroot /mnt grub-install --target=x86_64-efi --efi-directory=/boot/efi --bootloader-id=GRUB")
        else:
            self.run_command(f"arch-chroot /mnt grub-install --target=i386-pc {self.install_device}")
        
        if self.use_encryption:
            uuid = self.run_command(f"blkid -s UUID -o value {self.root_partition}", capture_output=True)
            self.run_command(f"echo 'GRUB_CMDLINE_LINUX=\"cryptdevice=UUID={uuid}:cryptroot root=/dev/mapper/cryptroot\"' >> /mnt/etc/default/grub")
            self.run_command("arch-chroot /mnt mkinitcpio -P")
        
        # Install GPU drivers before generating GRUB config (in case NVIDIA adds params)
        self.install_gpu_drivers()
        
        self.run_command("arch-chroot /mnt grub-mkconfig -o /boot/grub/grub.cfg")
        self.print_success("GRUB installed")
        
        self.run_command("arch-chroot /mnt systemctl enable NetworkManager")
        self.print_success("NetworkManager enabled")
        print()
        self.pause()
    
    def install_kde(self):
        self.print_header()
        print(f"{Colors.CYAN}[Step 12/12] KDE Plasma{Colors.NC}\n")
        print("Would you like to install KDE Plasma now?\n")
        print("This will download and run the XeroLinux KDE installer.\n")
        
        choice = self.get_input("Install KDE now? [y/N]: ")
        if choice.lower() == 'y':
            self.print_step("Downloading KDE installer...")
            
            kde_url = "https://xerolinux.xyz/script/xero-kde.sh"
            script_path = f"/mnt/home/{self.username}/xero-kde.sh"
            
            # Download script first
            download_result = self.run_command(f"curl -fsSL {kde_url} -o {script_path}", check=False)
            
            if not download_result:
                self.print_error("Failed to download KDE installer")
                print("\nYou can try again later by running:")
                print(f"  curl -fsSL {kde_url} | bash")
                print()
                self.pause()
                return
            
            # Make executable and set ownership
            self.run_command(f"chmod +x {script_path}")
            self.run_command(f"arch-chroot /mnt chown {self.username}:{self.username} /home/{self.username}/xero-kde.sh")
            
            self.print_step("Running KDE installer...")
            print("\nFollow the prompts to customize your KDE installation.\n")
            
            # Run with proper TTY allocation
            try:
                result = subprocess.run(
                    ["arch-chroot", "/mnt", "sudo", "-u", self.username, "bash", f"/home/{self.username}/xero-kde.sh"],
                    stdin=sys.stdin,
                    stdout=sys.stdout,
                    stderr=sys.stderr
                )
                
                if result.returncode == 0:
                    self.print_success("KDE installation complete!")
                else:
                    self.print_warning("KDE installation was cancelled or had issues")
                    print("\nYou can try again after reboot by running:")
                    print("  ~/xero-kde.sh")
            except Exception as e:
                self.print_error(f"KDE installation failed: {e}")
                print("\nYou can try again after reboot by running:")
                print("  ~/xero-kde.sh")
            
            # Cleanup script
            self.run_command(f"rm -f {script_path}", check=False)
        else:
            self.print_step("Skipping KDE installation")
            print("\nYou can install KDE later by running:")
            print("  curl -fsSL https://xerolinux.xyz/script/xero-kde.sh | bash")
        
        print()
        self.pause()
    
    def finalize(self):
        self.print_header()
        print(f"{Colors.CYAN}Installation Complete!{Colors.NC}\n")
        self.print_success("Installation complete!")
        print()
        print(f"{Colors.PURPLE}╔════════════════════════════════════════════════╗{Colors.NC}")
        print(f"{Colors.PURPLE}║{Colors.GREEN}         Installation Complete!                 {Colors.PURPLE}║{Colors.NC}")
        print(f"{Colors.PURPLE}╠════════════════════════════════════════════════╣{Colors.NC}")
        print(f"{Colors.PURPLE}║{Colors.NC}  System:   {self.hostname:<35}{Colors.PURPLE}║{Colors.NC}")
        print(f"{Colors.PURPLE}║{Colors.NC}  User:     {self.username:<35}{Colors.PURPLE}║{Colors.NC}")
        print(f"{Colors.PURPLE}║{Colors.NC}  Disk:     {self.install_device:<35}{Colors.PURPLE}║{Colors.NC}")
        print(f"{Colors.PURPLE}║{Colors.NC}  FS:       {self.filesystem.upper():<35}{Colors.PURPLE}║{Colors.NC}")
        print(f"{Colors.PURPLE}║{Colors.NC}                                                {Colors.PURPLE}║{Colors.NC}")
        print(f"{Colors.PURPLE}║{Colors.NC}  System will now reboot.                      {Colors.PURPLE}║{Colors.NC}")
        print(f"{Colors.PURPLE}╚════════════════════════════════════════════════╝{Colors.NC}")
        print()
        
        self.get_input("Press Enter to reboot...")
        self.run_command("umount -R /mnt")
        self.run_command("reboot")
    
    def run(self):
        try:
            self.preflight_checks()
            self.select_disk()
            self.detect_gpu()
            self.select_filesystem()
            self.partition_disk()
            self.format_partitions()
            self.mount_partitions()
            self.install_base_system()
            self.configure_repos()
            self.configure_system()
            self.configure_users()
            self.install_bootloader()
            self.install_kde()
            self.finalize()
        except KeyboardInterrupt:
            print(f"\n{Colors.RED}Cancelled{Colors.NC}")
            sys.exit(1)
        except Exception as e:
            print(f"\n{Colors.RED}Error: {e}{Colors.NC}")
            sys.exit(1)

if __name__ == "__main__":
    installer = Installer()
    installer.run()
