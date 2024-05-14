#!/usr/bin/env bash

# Functions
error() {
    echo "Error: $1" >&2
    exit 1
}

efi_boot_mode() {
    [[ -d /sys/firmware/efi/efivars ]] && return 0
    return 1
}

use_bcm4360() {
    return 1 # Return 0 for "truthy" and 1 for "falsy"
}

check_internet() {
    echo "Checking internet connection..."
    ping -c 3 archlinux.org &>/dev/null
    if [ $? -ne 0 ]; then
        error "Not Connected to Network!!!"
    fi
    echo "Internet connection detected."
    sleep 2
}

configure_mirrors() {
    clear
    echo "Do you want to configure the mirror list?"
    echo "1) Auto (default, press enter)"
    echo "2) Manual"
    echo "3) No"

    read -p "Enter choice [1-3]: " MIRROR_OPTION
    MIRROR_OPTION=${MIRROR_OPTION:-1}  # Default to 1 (Auto)

    case $MIRROR_OPTION in
        1)
            echo "Automatically configuring mirrors..."
            pacman -Sy --noconfirm reflector
            reflector --verbose --latest 10 --protocol https --sort rate --save /etc/pacman.d/mirrorlist || error "Reflector failed to configure mirrors."
            echo "Chosen mirrors for downloads:"
            grep 'Server = ' /etc/pacman.d/mirrorlist
            sleep 1
            ;;
        2) 
            echo "Choose mirror countries (e.g., 'United Kingdom,France,Belgium,Ireland'):" 
            echo "Available countries: Australia, Austria, Belarus, Belgium, Bosnia, Brazil, Bulgaria, Canada, Chile, China, Colombia, Croatia, Czech, Denmark, Estonia, Finland, France, Georgia, Germany, Greece, Hungary, Iceland, India, Indonesia, Ireland, Israel, Italy, Japan, Kazakhstan, Latvia, Lithuania, Luxembourg, Netherlands, New Zealand, Norway, Poland, Portugal, Romania, Russia, Serbia, Singapore, Slovakia, Slovenia, South Africa, South Korea, Spain, Sweden, Switzerland, Turkey, Ukraine, United Kingdom, United States"
            read -p "Enter mirror countries: " MIRRORS
            pacman -Sy --noconfirm reflector
            echo "Configuring the fastest mirrors with countries: ${MIRRORS}..."
            IFS=',' read -r -a mirror_array <<< "$MIRRORS"
            country_args=()
            for country in "${mirror_array[@]}"; do
                country_args+=( --country "$country" )
            done
            reflector --verbose "${country_args[@]}" --latest 10 --protocol https --sort rate --save /etc/pacman.d/mirrorlist || error "Failed to configure mirrors. Check your network connection or reflector settings."
            echo "Chosen mirrors for downloads:"
            grep 'Server = ' /etc/pacman.d/mirrorlist
            sleep 1
            ;;
        3)
            echo "Skipping mirror configuration..."
            return 0
            ;;
        *) 
            error "Invalid option"
            ;;
    esac
}

###############################
### START SCRIPT HERE
###############################

# Capture the start time
start_time=$(date +%s)

# Ensure the script runs as root
if [ "$EUID" -ne 0 ]; then
    error "Please run as root"
fi
clear

# Check internet connection before proceeding
check_internet

# Prompt for Hostname
read -p "Enter the hostname (computer name): " HOSTNAME

# Prompt for Root Password
while true; do
    echo "Set ROOT password..."
    read -s -p "Enter root password: " root_pass
    echo
    read -s -p "Confirm root password: " root_pass_confirm
    echo
    if [[ "$root_pass" == "$root_pass_confirm" ]]; then
        break
    else
        echo "Root passwords do not match. Try again."
    fi
done

# Prompt for Username
read -p "Enter the username: " sudo_user

# Prompt for User Password
while true; do
    echo "Set password for user $sudo_user..."
    read -s -p "Enter user password: " user_pass
    echo
    read -s -p "Confirm user password: " user_pass_confirm
    echo
    if [[ "$user_pass" == "$user_pass_confirm" ]]; then
        break
    else
        echo "User passwords do not match. Try again."
    fi
done

# Prompt for Disk and Partition Details
echo "List of available disks:"
lsblk -d -n -p -o NAME,SIZE,MODEL

read -p "Enter the disk to partition (e.g., /dev/sda): " IN_DEVICE

# Validate provided disk
if [ ! -e "$IN_DEVICE" ]; then
    error "Disk $IN_DEVICE does not exist."
fi

# Constants for partition sizes
read -p "Enter the size for the Boot partition (e.g., 512M): " BOOT_SIZE
read -p "Enter the size for the Swap partition (e.g., 2G): " SWAP_SIZE
read -p "Enter the size for the Root partition (e.g., 20G): " ROOT_SIZE

BOOT_DEVICE="${IN_DEVICE}1"
SWAP_DEVICE="${IN_DEVICE}2"
ROOT_DEVICE="${IN_DEVICE}3"
HOME_DEVICE="${IN_DEVICE}4"
TIME_ZONE="Europe/London"
LOCALE="en_US.UTF-8"
FILESYSTEM=ext4

if $(use_bcm4360); then
    WIRELESSDRIVERS="broadcom-wl-dkms"
else
    WIRELESSDRIVERS=""
fi

BASE_SYSTEM=( base base-devel linux linux-headers linux-firmware dkms vim iwd archlinux-keyring )
devel_stuff=( git nodejs npm npm-check-updates ruby )
printing_stuff=( system-config-printer foomatic-db foomatic-db-engine gutenprint cups cups-pdf cups-filters cups-pk-helper ghostscript gsfonts )
multimedia_stuff=( brasero sox eog shotwell imagemagick sox cmus mpg123 alsa-utils cheese )

# Configure Mirrors
configure_mirrors

# Check time and date before installation
timedatectl set-ntp true
echo && echo "Date/Time service status:"
timedatectl status
sleep 4

efi_boot_mode && error "You have a UEFI BIOS; Please use an appropriate script for installation"

# Create partitions using sfdisk
cat > /tmp/sfdisk.cmd <<EOF
$BOOT_DEVICE : start= 2048, size=+$BOOT_SIZE, type=83, bootable
$SWAP_DEVICE : size=+$SWAP_SIZE, type=82
$ROOT_DEVICE : size=+$ROOT_SIZE, type=83
$HOME_DEVICE : type=83
EOF
sfdisk "$IN_DEVICE" < /tmp/sfdisk.cmd || error "Partitioning the disk failed"

# Format filesystems
mkfs.ext4 -F "$BOOT_DEVICE" # /boot
mkfs.ext4 -F "$ROOT_DEVICE" # /
mkswap "$SWAP_DEVICE" # swap partition
mkfs.ext4 -F "$HOME_DEVICE" # /home

# Mount filesystems
mount "$ROOT_DEVICE" /mnt
mkdir /mnt/boot && mount "$BOOT_DEVICE" /mnt/boot
swapon "$SWAP_DEVICE"
mkdir /mnt/home && mount "$HOME_DEVICE" /mnt/home

# Install base system
clear
echo "Installing base system..."
pacstrap /mnt "${BASE_SYSTEM[@]}" || error "pacstrap failed. Check network connection and mirror configuration."

# Generate fstab
echo "Generating fstab..."
genfstab -U /mnt >> /mnt/etc/fstab || error "genfstab failed."
cat /mnt/etc/fstab

# Set up timezone and locale
clear
echo && echo "Setting timezone to $TIME_ZONE..."
arch-chroot /mnt ln -sf /usr/share/zoneinfo/"$TIME_ZONE" /etc/localtime || error "Setting timezone failed."
arch-chroot /mnt hwclock --systohc --utc || error "hwclock failed."

clear
echo && echo "Setting locale to $LOCALE ..."
arch-chroot /mnt sed -i "s/#$LOCALE/$LOCALE/g" /etc/locale.gen || error "Editing locale.gen failed."
arch-chroot /mnt locale-gen || error "Generating locales failed."
echo "LANG=$LOCALE" > /mnt/etc/locale.conf
export LANG="$LOCALE"
cat /mnt/etc/locale.conf

# Set hostname
clear
echo && echo "Setting hostname..."; sleep 3
echo "$HOSTNAME" > /mnt/etc/hostname
cat > /mnt/etc/hosts <<HOSTS
127.0.0.1 localhost
::1 localhost
127.0.1.1 $HOSTNAME.localdomain $HOSTNAME
HOSTS
echo && echo "/etc/hostname and /etc/hosts files configured..."
echo "/etc/hostname . . . "
cat /mnt/etc/hostname
echo "/etc/hosts . . ."
cat /mnt/etc/hosts

# Set root password
clear
echo "Setting ROOT password..."
echo -e "$root_pass\n$root_pass" | arch-chroot /mnt passwd

# Installing more essentials
clear
echo && echo "Enabling dhcpcd, pambase, sshd, and NetworkManager services..." && echo
arch-chroot /mnt pacman -S --noconfirm git openssh networkmanager dhcpcd man-db man-pages pambase || error "Installing essentials failed."
arch-chroot /mnt systemctl enable dhcpcd.service || error "Enabling dhcpcd failed."
arch-chroot /mnt systemctl enable sshd.service || error "Enabling sshd failed."
arch-chroot /mnt systemctl enable NetworkManager.service || error "Enabling NetworkManager failed."

# Add user account
clear
echo && echo "Adding sudo + user account..." sleep 2
arch-chroot /mnt pacman -S --noconfirm sudo bash-completion sshpass || error "Installing sudo and bash-completion failed."
arch-chroot /mnt sed -i 's/# %wheel/%wheel/g' /etc/sudoers
arch-chroot /mnt sed -i 's/%wheel ALL=(ALL) NOPASSWD: ALL/# %wheel ALL=(ALL) NOPASSWD: ALL/g' /etc/sudoers
echo && echo "Creating $sudo_user and adding $sudo_user to sudoers..."
arch-chroot /mnt useradd -m -G wheel "$sudo_user" || error "Creating user account failed."
echo "Setting password for $sudo_user..."
echo -e "$user_pass\n$user_pass" | arch-chroot /mnt passwd "$sudo_user"

# Install WiFi drivers
$(use_bcm4360) && arch-chroot /mnt pacman -S --noconfirm "$WIRELESSDRIVERS"
[[ "$?" -eq 0 ]] && echo "WiFi driver successfully installed!" && sleep 5

# Install Xorg and basic utilities
clear
echo "Installing Xorg and basic utilities..."
arch-chroot /mnt pacman -S --noconfirm xorg-server xorg-apps xorg-xinit xterm

# Install necessary dependencies for dwm
echo "Installing dependencies for dwm..."
arch-chroot /mnt pacman -S --needed base-devel libx11 libxft libxinerama freetype2 fontconfig xcompmgr xwallpaper terminus-font xterm openssh xdotool --noconfirm

# Install zsh and dotfiles
clear
echo "Installing zsh and your dotfiles..."
arch-chroot /mnt sudo pacman -Syu --needed zsh git libnotify imagemagick stow alacritty dunst tmux firefox unclutter awesome kitty rofi conky fish lf nsxiv neofetch picom redshift systemd xf86-input-libinput gimp gnupg pass zathura zoxide wget alsa-utils eza flameshot gpick python-pip --noconfirm
arch-chroot /mnt sudo -u "$sudo_user" bash -c "
    git clone https://github.com/Paulobox/archdots /home/$sudo_user/archdots &&
    mv /home/$sudo_user/archdots/.config /home/$sudo_user/.config &&
    mv /home/$sudo_user/archdots/.dotfiles /home/$sudo_user/.dotfiles &&
    rm -rf /home/$sudo_user/archdots &&
    chmod +x /home/$sudo_user/.dotfiles/myscripts/.myscripts/*
"

# Clone, build, and install your custom dwm setup
clear
echo "Cloning, building, and installing your custom dwm setup..."
arch-chroot /mnt sudo -u "$sudo_user" git clone https://github.com/Paulobox/suckless-software /home/"$sudo_user"/suckless-software
arch-chroot /mnt bash -c "
    cd /home/$sudo_user/suckless-software/dwm && make clean install
    cd /home/$sudo_user/suckless-software/dmenu && make clean install
    cd /home/$sudo_user/suckless-software/st && make clean install
"

# Create symbolic links and set permissions
arch-chroot /mnt sudo -u "$sudo_user" ln -sf /home/"$sudo_user"/.config/shell/profile /home/"$sudo_user"/.zprofile
arch-chroot /mnt sudo -u "$sudo_user" ln -sf /home/"$sudo_user"/.config/x11/xprofile /home/"$sudo_user"/.xprofile
arch-chroot /mnt sudo -u "$sudo_user" chmod +x /home/"$sudo_user"/.config/{x11/*,shell/*}

# Install GRUB and finalize installation steps
clear
echo "Installing grub..." && sleep 4
arch-chroot /mnt pacman -S --noconfirm grub os-prober || error "Installing GRUB failed."
## Assume BIOS
arch-chroot /mnt grub-install --target=i386-pc "$IN_DEVICE" || error "GRUB installation failed."
echo "Configuring /boot/grub/grub.cfg..."
arch-chroot /mnt grub-mkconfig -o /boot/grub/grub.cfg || error "GRUB configuration failed."
[[ "$?" -eq 0 ]] && echo "BIOS bootloader installed."

# Capture the end time
end_time=$(date +%s)
# Calculate the elapsed time
elapsed_time=$(( end_time - start_time ))
# Convert elapsed time to minutes and seconds
elapsed_minutes=$(( elapsed_time / 60 ))
elapsed_seconds=$(( elapsed_time % 60 ))
echo "Your system is installed. It took $elapsed_minutes minutes and $elapsed_seconds seconds to install Arch Linux + X + dwm(window manager) **[once logged in type: startx]**. Press enter to reboot."
read empty
# Reboot system
reboot
