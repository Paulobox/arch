<h1 text align=center>  Arch installer script [minimal arch] <br> (on Vmware) </h1>


<h2> option |1| One command to run after booting into Arch iso [to install minimal arch] (on Vmware) </h2>

```
bash <(curl -L raw.githubusercontent.com/paulobox/arch/main/vm-ware.sh)
```

<h3> option |2| aio [ALL in One] choose vanilla desktop dwm or i3 in the installer script (on Vmware)</h3>

```
bash <(curl -L raw.githubusercontent.com/paulobox/arch/main/aio.sh)
```

<br>


---

## Working 
- [x] vm-ware.sh [automated install BASIC minimal Arch install script [tested on VMware] ]
- [x] aio.sh [All in One choose between i3 and dwm and no desktop [tested on VMware] ]
- [x] i3.sh [X + i3 [tested on VMware] ]
- [x] dwm.sh [x + dwm+st [tested on VMware] ]

---

##### TODO
- [ ] add manual partitioning option
- [ ] add option to choose favorite text editor
- [ ] add option to install not only on Vmware

---

### Tweak settings yourself (download & edit with nano)
```
curl -LO https://raw.githubusercontent.com/paulobox/arch/main/vm-ware.sh
nano vm-ware.sh
chmod +x vm-ware.sh
./vm-ware.sh
```

<br>

######
These Scripts I made are Inspired by: [Farchi](https://github.com/deepbsd/Farchi) - Fast Arch Linux Installer.




<!--

## Arch-install.sh

```
curl -LO https://raw.githubusercontent.com/Paulobox/arch/main/arch-install.sh
chmod +x arch-install.sh
./arch-install.sh
```

---
---
---
---

# Manual instalation below

### Connecting to the internet (Arch Install)

###### adapter powered off(fix)
```
rfkill list
rfkill unblock 4
iwctl device wlan0 set-property Powered on;
```
###### Connect to wi-fi
```
iwctl
device list
station wlan0 scan
station wlan0 get-networks
station wlan0 connect MyWiFiNetwork
exit
```

# A Step-by-Step Guide to Installing Arch Linux

Are you looking to delve into the world of Arch Linux, a powerful and customizable Linux distribution favored by enthusiasts and advanced users alike? In this guide, we'll walk you through the process of installing Arch Linux on your system, step by step. By the end of this tutorial, you'll have a fully functional Arch Linux installation ready to explore and customize to your heart's content.

## Prerequisites

- A computer or virtual machine with a compatible processor architecture (x86-64).
- A stable internet connection.
- Basic familiarity with the Linux command line.

## Step 1: Download the Arch Linux ISO

The first step is to download the Arch Linux ISO image from the official website. Visit [archlinux.org/download](https://archlinux.org/download) and select a mirror closest to your location to download the ISO file.

## Step 2: Create a Bootable USB Drive

Once the ISO file is downloaded, you'll need to create a bootable USB drive. You can use tools like Rufus (for Windows) or `dd` (for Linux) to write the ISO image to a USB drive.

## Step 3: Boot into the Arch Linux Live Environment

Insert the bootable USB drive into your computer and boot from it. You should boot into the Arch Linux live environment.

## Step 4: Prepare the Disk

Once booted into the live environment, use the `lsblk` command to identify your disk devices. For example:

```
lsblk
```
Use cfdisk or another partitioning tool to partition your disk. For example:

```
cfdisk /dev/sda
```
Create partitions for root (/), swap, and any other desired partitions.

## Step 5: Format the Partitions
Format the root partition with the ext4 filesystem:

```
mkfs.ext4 /dev/sdaX
```

## Step 6: Mount the Partitions

root
```
mount /dev/sdaX /mnt
```

boot

```
mkdir -p /mnt/boot/efi
mount /dev/sdX /mnt/boot/efi
```

swap

```
swap on /dev/sdX
```



## Step 7: Install Arch Linux
Install the base Arch Linux system using the pacstrap command. Include essential packages such as base, linux, linux-firmware, nano, grub, and dhcpcd. For example:

```
pacstrap /mnt base linux linux-firmware nano vim grub networkmanager sudo git base-devel
```

## Step 8: Generate an fstab File
Generate an fstab file for the newly installed system:

```
genfstab /mnt
```


```
genfstab -U /mnt >> /mnt/etc/fstab
```

##### cat /mnt/etc/fstab

## Step 9: Chroot into the Installed System
Change root into the newly installed system:

```
arch-chroot /mnt
```

## Step 10: Configure the System

After installing the base Arch Linux system, it's essential to configure it according to your preferences and requirements. Here's how you can do it:
<br><br>
dont forget to change root passwd from within installation media just type <br><br> 

```
passwd
```
 <br><br>
<details>
<summary>Set the Timezone</summary>

```
ln -sf /usr/share/zoneinfo/Europe/London /etc/localtime
date
```

- synchronize time

hwclock --systohc

You can set the timezone using the `timedatectl` command. For example, to set the timezone to `America/New_York`, you can use:

```bash
timedatectl set-timezone America/New_York
```
</details>

<details>
<summary>Set the Locale</summary>

To set the system locale, you need to edit the `/etc/locale.gen` file and uncomment the desired locale(s). For example, to enable the `en_US.UTF-8` locale, you can edit the file using a text editor like `nano`:

```bash
nano /etc/locale.gen
```

Uncomment the line that corresponds to your desired locale, then generate the locale with:


Finally, set the `LANG` variable in the `/etc/locale.conf` file to your desired locale. For example:

```bash
locale-gen
```

<hr/>

```bash
echo "LANG=en_US.UTF-8" > /etc/locale.conf
```

/etc/vconsole.conf

```
KEYMAP=us
```


</details>

### Set the Hostname

To set the hostname of your system, edit the `/etc/hostname` file and enter your desired hostname. For example:

```bash
echo "myhostname" > /etc/hostname
```

### Create a User Account

You can create a new user account using the `useradd` command. For example, to create a user named `myuser`, you can use:

```bash
useradd -m myuser
```

or with group:

```bash
useradd -m -G wheel myuser
```

Then, set a password for the new user:

```bash
passwd myuser
```

### Grant sudo Privileges

If you want the new user to have sudo privileges, you can add them to the `wheel` group. Edit the `/etc/sudoers` file using the `visudo` command:

```bash
visudo
```

Uncomment the line that allows members of the `wheel` group to execute any command with sudo:

```bash
%wheel ALL=(ALL) ALL
```

Save and exit the editor.<br>

EDITOR=nano visudo


# network 

```
systemctl enable NetworkManager
```

###### optional if lightdm

```
systemctl enable lightdm
```

## Step 11: Install and Configure Bootloader
Install the GRUB bootloader to the disk:

```
grub-install --target=/dev/sda
```

##### vm

```
grub-install --target=i386-pc /dev/sda
```
Generate the GRUB configuration file:

```
grub-mkconfig -o /boot/grub/grub.cfg
```


can enable os-prober if dual booting

### Step 12: Reboot
Exit the chroot environment and reboot the system:

```
umount -a
exit
reboot
```


once booted connect to wifi or run systemctl reboot NetworkManager and run

```
nmcli device wifi list
nmcli device wifi connect <SSID> password <password>
```

# The End

Congratulations! You've successfully installed Arch Linux on your system. Enjoy exploring and customizing your new Arch Linux installation!

<hr/>
<br><br>

## Arch install script

<details><summary>arch install script not working</summary>

 ```
curl -O https://raw.githubusercontent.com/Paulobox/arch/main/arch-install.sh
chmod + arch-install.sh
./arch-install.sh
```

</details>

<details>
<summary><b>If something goes wrong wipe it and start again</b></summary>

```
umount /dev/sda*
swapoff /dev/sda*
wipefs -a /dev/sda

dd if=/dev/zero of=/dev/sda bs=1M count=100
lsblk /dev/sda
```

-->
</details>

