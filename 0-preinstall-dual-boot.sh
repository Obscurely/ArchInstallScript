echo "*************************************************"
echo "*  Before setup give password for installation  *"
echo "*************************************************"
# dialog for hostname and username
echo -n "Username: "
read -s username
echo
# dialog to verify if passwords match and if they do then it stores the password in the var $password
echo -n "Password: "
read -s password
echo
echo -n "Repeat Password: "
read -s password2
echo
[[ "$password" == "$password2" ]] || ( echo "Passwords did not match"; exit 1; )


echo "*************************************************"
echo "**                                             **"
echo "*       Arch Install (script part 1 of 2)       *"
echo "**                                             **"
echo "*************************************************"

echo "*************************************************"
echo "* Setting up mirrors for optimal download       *"
echo "*************************************************"
iso=$(curl -4 ifconfig.co/country-iso)
timedatectl set-ntp true
pacman -S --noconfirm pacman-contrib terminus-font
setfont ter-v22b
pacman -S --noconfirm reflector rsync
mv /etc/pacman.d/mirrorlist /etc/pacman.d/mirrorlist.backup
reflector -a 48 -c $iso -f 5 -l 20 --sort rate --save /etc/pacman.d/mirrorlist
pacman -Sy
mkdir /mnt


echo "*************************************************"
echo "* Setting keyboard layout                       *"
echo "*************************************************"
loadkeys us


echo "*************************************************"
echo "* Mounting disks.                           *"
echo "*************************************************"
echo "Installing prereqs...\n"
pacman -S --noconfirm gptfdisk btrfs-progs f2fs-tools

# Label partitions
echo "Labeling partitions."

sgdisk -c 5:"UEFISYS" /dev/nvme0n1
sgdisk -c 3:"SWAP" /dev/sda 
sgdisk -c 6:"ROOT" /dev/nvme0n1 
sgdisk -c 4:"HOME" /dev/sda

# Make filesystems
echo "Making file systems."

 # on /dev/nvme0n1 (nvme ssd)
mkfs.vfat -F32 -n "UEFISYS" "/dev/nvme0n1p5" # formating efi partition with fat.
mkswap -L "SWAP" "/dev/sda3" # formating swap partition with linux swap.
mkfs.f2fs -f -l "ROOT" "/dev/nvme0n1p6" # formating root partition with f2fs.
mkfs.f2fs -f -l "HOME" "/dev/sda4" # formating home partition with f2fs.

# Create dirs for targets
mkdir /mnt/boot # makes boot dir
mkdir /mnt/home # makes home dir

# Mount targets
mount "/dev/nvme0n1p6" /mnt # mounts root
mount "/dev/nvme0n1p5" /mnt/boot # mounts boot 
mount "/dev/sda4" /mnt/home # mounts home 
swapon "/dev/sda3" # turns swap on


echo "*************************************************"
echo "* Arch Install on Main Drive                    *"
echo "*************************************************"
pacstrap /mnt base base-devel linux-zen linux-zen-headers linux-firmware vim nano sudo archlinux-keyring dosfstools btrfs-progs f2fs-tools grub efibootmgr wget libnewt --noconfirm --needed
genfstab -U -p /mnt > /mnt/etc/fstab
echo "keyserver hkp://keyserver.ubuntu.com" >> /mnt/etc/pacman.d/gnupg/gpg.conf
echo "Done"
