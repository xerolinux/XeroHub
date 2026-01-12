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
        print(f"{Colors.CYAN}[Step 1/10] Select Disk{Colors.NC}\n")
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

    def select_filesystem(self):
        self.print_header()
        print(f"{Colors.CYAN}[Step 1.5/10] Configuration{Colors.NC}\n")

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

        self.print_success(f"Keymap: {self.keymap}")
        print()

        # Encryption
        encrypt = self.get_input("Encrypt root partition? [y/N]: ")
        if encrypt.lower() == 'y':
            self.use_encryption = True
            while True:
                self.luks_password = self.get_input("Encryption password: ")
                confirm = self.get_input("Confirm password: ")
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
        print(f"{Colors.CYAN}[Step 2/10] Partitioning{Colors.NC}\n")
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
        print(f"{Colors.CYAN}[Step 3/10] Formatting{Colors.NC}\n")

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
        print(f"{Colors.CYAN}[Step 4/10] Mounting{Colors.NC}\n")
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
        print(f"{Colors.CYAN}[Step 5/10] Base System{Colors.NC}\n")
        self.print_step("Installing base system...")

        packages = ["base", "base-devel", "linux", "linux-firmware", "linux-headers",
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

    def configure_system(self):
        self.print_header()
        print(f"{Colors.CYAN}[Step 6/10] System Config{Colors.NC}\n")

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
        print(f"{Colors.CYAN}[Step 7/10] Users{Colors.NC}\n")

        while True:
            root_pass = self.get_input("Root password: ")
            confirm = self.get_input("Confirm: ")
            if root_pass == confirm:
                self.run_command(f"arch-chroot /mnt bash -c \"echo 'root:{root_pass}' | chpasswd\"")
                self.print_success("Root password set")
                break
            else:
                self.print_error("Passwords don't match!")

        print()
        self.username = self.get_input("Username: ")
        self.run_command(f"arch-chroot /mnt useradd -m -G wheel,audio,video,storage -s /bin/bash {self.username}")

        while True:
            user_pass = self.get_input(f"Password for {self.username}: ")
            confirm = self.get_input("Confirm: ")
            if user_pass == confirm:
                self.run_command(f"arch-chroot /mnt bash -c \"echo '{self.username}:{user_pass}' | chpasswd\"")
                self.print_success(f"User {self.username} created")
                break
            else:
                self.print_error("Passwords don't match!")

        self.run_command("sed -i 's/^# %wheel ALL=(ALL:ALL) ALL/%wheel ALL=(ALL:ALL) ALL/' /mnt/etc/sudoers")
        print()
        self.pause()

    def install_bootloader(self):
        self.print_header()
        print(f"{Colors.CYAN}[Step 8/10] Bootloader{Colors.NC}\n")
        self.print_step("Installing GRUB...")

        if self.is_uefi:
            self.run_command("arch-chroot /mnt grub-install --target=x86_64-efi --efi-directory=/boot/efi --bootloader-id=GRUB")
        else:
            self.run_command(f"arch-chroot /mnt grub-install --target=i386-pc {self.install_device}")

        if self.use_encryption:
            uuid = self.run_command(f"blkid -s UUID -o value {self.root_partition}", capture_output=True)
            self.run_command(f"echo 'GRUB_CMDLINE_LINUX=\"cryptdevice=UUID={uuid}:cryptroot root=/dev/mapper/cryptroot\"' >> /mnt/etc/default/grub")
            self.run_command("arch-chroot /mnt mkinitcpio -P")

        self.run_command("arch-chroot /mnt grub-mkconfig -o /boot/grub/grub.cfg")
        self.print_success("GRUB installed")

        self.run_command("arch-chroot /mnt systemctl enable NetworkManager")
        self.print_success("NetworkManager enabled")
        print()
        self.pause()

    def install_kde(self):
        self.print_header()
        print(f"{Colors.CYAN}[Step 9/10] KDE Plasma{Colors.NC}\n")
        print("Would you like to install KDE Plasma now?\n")
        print("This will download and run the XeroLinux KDE installer.\n")

        choice = self.get_input("Install KDE now? [y/N]: ")
        if choice.lower() == 'y':
            self.print_step("Downloading and running KDE installer...")

            # Run the KDE installer directly via curl as the user in chroot
            # The script is downloaded and executed in one command
            kde_url = "https://xerolinux.xyz/scripts/xero-kde-installer.sh"

            install_cmd = f'arch-chroot /mnt sudo -u {self.username} bash -c "curl -fsSL {kde_url} | bash"'

            print("\nFollow the prompts to customize your KDE installation.\n")

            result = self.run_command(install_cmd, check=False)

            if result:
                self.print_success("KDE installation complete!")
            else:
                self.print_warning("KDE installation had issues")
                print("\nYou can try again later by running:")
                print(f"  curl -fsSL {kde_url} | bash")
        else:
            self.print_step("Skipping KDE installation")
            print("\nYou can install KDE later by running:")
            print("  curl -fsSL https://xerolinux.xyz/script/xero-kde.sh | bash")

        print()
        self.pause()

    def finalize(self):
        self.print_header()
        print(f"{Colors.CYAN}[Step 10/10] Complete{Colors.NC}\n")
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
            self.select_filesystem()
            self.partition_disk()
            self.format_partitions()
            self.mount_partitions()
            self.install_base_system()
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
