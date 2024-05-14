# ==** ARCH + DWM INSTALL **== #
#part1
printf '\033c'
echo "welcome to Arch + DWM install script"
sed -i "s/^#ParallelDownloads = 5$/ParallelDownloads = 15/" /etc/pacman.conf
pacman --noconfirm -Sy archlinux-keyring
loadkeys us
timedatectl set-ntp true
echo "-----------------------------------------------------------------------------------------"
echo "------DISKS(↓)------"
echo "-----------------------------------------------------------------------------------------"
lsblk
echo "------------------------------------------------------------------------------"
echo "Enter the drive (example: /dev/sda or /dev/nvme0n1) for partitioning with cfdisk"
echo "------------------------------------------------------------------------------"
echo "1. create (type=BIOS boot (size 1MB-5GB)"
echo "------------------------------------------------------------------------------"
echo "2. create (type=Linux-swap (size 1-5GB)"
echo "------------------------------------------------------------------------------"
echo "3. create (type=Linux filesystem) (size the rest of the disk or your choice)"
echo "------------------------------------------------------------------------------"
echo "[In CFDISK] [click Write,type yes],click Quit"
echo "-----------------------------------------------------------------------------------------"
read drive
cfdisk $drive
echo " (mkfs.ext4)Enter the linux partition [[ /dev/sda3 or /dev/nvme0n1p3 ]] "
read partition
mkfs.ext4 $partition
echo "Enter swap partition [[ /dev/sda2 or /dev/nvme0n1p2 ]] : "
mkswap $swap
swap on $swap
mount $partition /mnt
pacstrap /mnt base base-devel linux linux-firmware connman nano vim sudo dhcpcd grub
genfstab /mnt
sleep 1
genfstab /mnt >> /mnt/etc/fstab
sed '1,/^#part2$/d' `basename $0` > /mnt/arch_install2.sh
chmod +x /mnt/arch_install2.sh
arch-chroot /mnt ./arch_install2.sh
exit 

#part2
printf '\033c'
systemctl start connman.service
sleep 1
systemctl enable connman.service
sleep 2
echo "Enter Admin(root) password"
passwd
echo "Hostname(name your computer): "
read hostname
echo $hostname > /etc/hostname
echo "%wheel ALL=(ALL) NOPASSWD: ALL" >> /etc/sudoers
echo "Enter Username: "
read username
useradd -m -G wheel -s /bin/zsh $username
passwd $username
sed -i "s/^#ParallelDownloads = 5$/ParallelDownloads = 15/" /etc/pacman.conf
ln -sf /usr/share/zoneinfo/Europe/London /etc/localtime
hwclock --systohc
echo "en_US.UTF-8 UTF-8" >> /etc/locale.gen
locale-gen
echo "LANG=en_US.UTF-8" > /etc/locale.conf
echo "KEYMAP=us" > /etc/vconsole.conf
mkdir /boot/efi
mount $efipartition /boot/efi 
grub-install $drive
grub-mkconfig -o /boot/grub/grub.cfg

pacman -S --noconfirm --needed xorg-server xorg-xinit xorg-xkill xorg-xsetroot xorg-xbacklight xorg-xprop \
     noto-fonts-emoji ttf-font-awesome \
     nsxiv mpv zathura zathura-pdf-mupdf ffmpeg imagemagick \
     fzf man-db xwallpaper python-pywal unclutter xclip maim \
     zip unzip unrar p7zip xdotool papirus-icon-theme brightnessctl \
     dosfstools ntfs-3g git sxhkd zsh pipewire pipewire-pulse \
     emacs-nox arc-gtk-theme rsync qutebrowser dash \
     xcompmgr libnotify dunst w3m slock jq aria2 cowsay \
     wpa_supplicant rsync pamixer mpd ncmpcpp \
     zsh-syntax-highlighting xdg-user-dirs libconfig \
     bluez bluez-utils

echo "Pre-Installation Finish Reboot now"
ai3_path=/home/$username/arch_install3.sh
sed '1,/^#part3$/d' arch_install2.sh > $ai3_path
chown $username:$username $ai3_path
chmod +x $ai3_path
su -c $ai3_path -s /bin/sh $username
exit 

#part3
printf '\033c'
cd $HOME
git clone --separate-git-dir=$HOME/.dotfiles https://github.com/bugswriter/dotfiles.git tmpdotfiles
rsync --recursive --verbose --exclude '.git' tmpdotfiles/ $HOME/
rm -r tmpdotfiles
# dwm: Window Manager
git clone --depth=1 https://github.com/Bugswriter/dwm.git ~/.local/src/dwm
sudo make -C ~/.local/src/dwm install

# st: Terminal
git clone --depth=1 https://github.com/Bugswriter/st.git ~/.local/src/st
sudo make -C ~/.local/src/st install

# dmenu: Program Menu
git clone --depth=1 https://github.com/Bugswriter/dmenu.git ~/.local/src/dmenu
sudo make -C ~/.local/src/dmenu install

# dmenu: Dmenu based Password Prompt
git clone --depth=1 https://github.com/ritze/pinentry-dmenu.git ~/.local/src/pinentry-dmenu
sudo make -C ~/.local/src/pinentry-dmenu clean install

# dwmblocks: Status bar for dwm
git clone --depth=1 https://github.com/bugswriter/dwmblocks.git ~/.local/src/dwmblocks
sudo make -C ~/.local/src/dwmblocks install

# yay: AUR helper
pacman -S --needed git base-devel && git clone https://aur.archlinux.org/yay.git && cd yay && echo "Y" | makepkg -si
yay -S --needed libxft-bgra-git yt-dlp-drop-in ttf-times-new-roman --noconfirm
mkdir Downloads Documents Music Pictures/wallpapers

ln -s ~/.config/x11/xinitrc .xinitrc
ln -s ~/.config/shell/profile .zprofile
sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)"
mv -f ~/.oh-my-zsh ~/.config/zsh/oh-my-zsh
rm -f ~/.zshrc ~/.zsh_history
alias dots='/usr/bin/git --git-dir=$HOME/.dotfiles/ --work-tree=$HOME'
dots config --local status.showUntrackedFiles no
exit
