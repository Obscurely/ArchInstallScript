echo "*************************************************"
echo "*  Before setup give password for installation  *"
echo "*************************************************"
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
pacman -S --noconfirm pacman-contrib
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
echo "* Partitioning disks.                           *"
echo "*************************************************"
echo "Installing prereqs...\n"
pacman -S --noconfirm gptfdisk btrfs-progs f2fs-tools

# Zap everything on the disks
echo "Formating all disks."

sgdisk -Z /dev/nvme0n1
sgdisk -Z /dev/sda
sgdisk -Z /dev/sdb

# Create new partition tables (GPT) of 2048 alignment
echo "Creating new partition tables of type GPT of 2048 alignment."

sgdisk -a 2048 -o /dev/nvme0n1
sgdisk -a 2048 -o /dev/sda
sgdisk -a 2048 -o /dev/sdb

# Create partitons
echo "Making partitions."

 # on /dev/nvme0n1 (nvme ssd)
sgdisk -n 1:0:+1024M /dev/nvme0n1 # partition 1 (EFI), 1GB
sgdisk -n 2:0:+16384M /dev/nvme0n1 # partition 2 (SWAP), 16GB
sgdisk -n 3:0:+51200M /dev/nvme0n1 # partition 3 (ROOT), 50GB
sgdisk -n 4:0:0 /dev/nvme0n1 # partition 4 (HOME), the rest, 350GB+
 # on /dev/sda (sata ssd)
sgdisk -n 1:0:0 /dev/sda # partition 1 (DATA), all, about 930GB
 # on /dev/sdb (sshd)
sgdisk -n 1:0:0 /dev/sdb # partition 1 (EXTRA), all, about 1.80GB

# Set partition types
echo "Setting partition types."

 # on /dev/nvme0n1 (nvme ssd)
sgdisk -t 1:ef00 /dev/nvme0n1 # making partition 1 type efi
sgdisk -t 2:8200 /dev/nvme0n1 # making partition 2 type linux swap
sgdisk -t 3:8300 /dev/nvme0n1 # making partition 3 type linux file system
sgdisk -t 4:8300 /dev/nvme0n1 # making partition 4 type linux file system
 # on /dev/sda (sata ssd)
sgdisk -t 1:8300 /dev/sda # making partition 1 type linux file system
 # on /dev/sdb (sshd)
sgdisk -t 1:8300 /dev/sdb # making partition 1 type linux file system

# Label partitions
echo "Labeling partitions."

 # on /dev/nvme0n1 (nvme ssd)
sgdisk -c 1:"UEFISYS" /dev/nvme0n1
sgdisk -c 2:"SWAP" /dev/nvme0n1 
sgdisk -c 3:"ROOT" /dev/nvme0n1 
sgdisk -c 4:"HOME" /dev/nvme0n1
 # on /dev/sda (sata ssd)
sgdisk -c 1:"DATA" /dev/sda
 # on /dev/sdb (sshd)
sgdisk -c 1:"EXTRA" /dev/sdb

# Make filesystems
echo "Making file systems."

 # on /dev/nvme0n1 (nvme ssd)
mkfs.vfat -F32 -n "UEFISYS" "/dev/nvme0n1p1" # formating efi partition with fat.
mkswap -L "SWAP" "/dev/nvme0n1p2" # formating swap partition with linux swap.
mkfs.f2fs -f -l "ROOT" "/dev/nvme0n1p3" # formating root partition with f2fs.
mkfs.f2fs -f -l "HOME" "/dev/nvme0n1p4" # formating home partition with f2fs.
 # on /dev/sda (sata ssd)
mkfs.f2fs -f -l "DATA" "/dev/sda1" # formating data partition with f2fs.
 # on /dev/sdb (sshd)
mkfs.btrfs -f -L "EXTRA" "/dev/sdb1"

# Create dirs for targets
mkdir /mnt/boot # makes boot dir
mkdir /mnt/home # makes home dir
mkdir /mnt/data # makes data dir
mkdir /mnt/extra # make extra dir

# Mount targets
mount "/dev/nvme0n1p3" /mnt # mounts root
mount "/dev/nvme0n1p1" /mnt/boot # mounts boot 
mount "/dev/nvme0n1p4" /mnt/home # mounts home 
mount "/dev/sda1" /mnt/data # mounts data
mount "/dev/sdb1" /mnt/extra # mounts extra
swapon "/dev/nvme0n1p2" # turns swap on


echo "*************************************************"
echo "* Arch Install on Main Drive                    *"
echo "*************************************************"
pacstrap /mnt base base-devel linux-zen linux-zen-headers linux-firmware vim nano sudo archlinux-keyring dosfstools btrfs-progs f2fs-tools grub efibootmgr wget libnewt --noconfirm --needed
genfstab -U -p /mnt > /mnt/etc/fstab
echo "keyserver hkp://keyserver.ubuntu.com" >> /mnt/etc/pacman.d/gnupg/gpg.conf


echo "**********************************************************"
echo "* Configuring Arch (the system its self not the desktop) *"
echo "**********************************************************"
arch-chroot /mnt


echo "***************************************"
echo "**          Network Setup            **"
echo "***************************************"
pacman -S networkmanager dhcpcd --noconfirm --needed
systemctl enable --now NetworkManager


echo "***************************************"
echo "**      Set Password for Root        **"
echo "***************************************"
echo "root:$password" | chpasswd


echo "**************************************************"
echo "* Setting up mirrors for optimal download        *"
echo "**************************************************"
pacman -S --noconfirm pacman-contrib curl
pacman -S --noconfirm reflector rsync
iso=$(curl -4 ifconfig.co/country-iso)
cp /etc/pacman.d/mirrorlist /etc/pacman.d/mirrorlist.bak
reflector -a 48 -c $iso -f 5 -l 20 --sort rate --save /etc/pacman.d/mirrorlist

nc=$(grep -c ^processor /proc/cpuinfo) # cpu cores
# Change makeflags for cores
sudo sed -i 's/#MAKEFLAGS="-j2"/MAKEFLAGS="-j$nc"/g' /etc/makepkg.conf
sudo sed -i 's/COMPRESSXZ=(xz -c -z -)/COMPRESSXZ=(xz -c -T $nc -z -)/g' /etc/makepkg.conf


echo "**************************************************"
echo "**     Setup Language to US and set locale      **"
echo "**************************************************"
# Set locale
sed -i 's/^#en_US.UTF-8 UTF-8/en_US.UTF-8 UTF-8/' /etc/locale.gen
locale-gen
timedatectl --no-ask-password set-timezone Europe/Bucharest
timedatectl --no-ask-password set-ntp 1
localectl --no-ask-password set-locale LANG="en_US.UTF-8" LC_COLLATE="C" LC_TIME="en_US.UTF-8"
hwclock --systohc --utc

# Set keymaps
localectl --no-ask-password set-keymap us

# Set computer name
hostnamectl --no-ask-password set-hostname "netrunner"

# Add sudo no password rights
sed -i 's/^# %wheel ALL=(ALL) NOPASSWD: ALL/%wheel ALL=(ALL) NOPASSWD: ALL/' /etc/sudoers

# Add parallel downloading
sed -i 's/^#Para/Para/' /etc/pacman.conf

# Enable multilib
cat <<EOF >> /etc/pacman.conf
[multilib]
Include = /etc/pacman.d/mirrorlist
EOF
pacman -Sy --noconfirm

# Set up mkinitcpio for nvme
sed -i "s/MODULES=()/MODULES=(nvme)/g" /etc/mkinitcpio.conf
mkinitcpio -p linux


echo "**************************************************"
echo "**            Setup Grub Bootloader             **"
echo "**************************************************"
mkdir /boot/grub
grub-mkconfig -o /boot/grub/grub.cfg
grub-install --target=x86_64-efi --efi-directory=/boot --bootloader-id=GRUB


echo "**************************************************"
echo "**                                              **"
echo "*   Arch DE Configuration (script part 2 of 2)   *"
echo "**                                              **"
echo "**************************************************"

echo "**************************************************"
echo "**       Installing packages from pacman        **"
echo "**************************************************"
# enabling chaotic-aur
pacman-key --recv-key 3056513887B78AEB --keyserver keyserver.ubuntu.com
pacman-key --lsign-key 3056513887B78AEB
pacman -U 'https://cdn-mirror.chaotic.cx/chaotic-aur/chaotic-keyring.pkg.tar.zst' 'https://cdn-mirror.chaotic.cx/chaotic-aur/chaotic-mirrorlist.pkg.tar.zst'
echo "[chaotic-aur]
Include = /etc/pacman.d/chaotic-mirrorlist" >> /etc/pacman.conf

# updating pacman in order to download lates packages
pacman -Sy archlinux-keyring ---noconfirm

# packages list
PKGS=(
    'alsa-utils' # sound support
    'alsa-plugins' # extra alsa plugins
    'amd-ucode'
    'ark'
    'audiocd-kio' 
    'base'
    'base-devel'
    'bash-completition'
    'bind'
    'binutils'
    'bleachbit' # Profile Cleaner
    'breeze'
    'breeze-gtk'
    'btrfs-progs' # brtfs file utils
    'clementine'
    'code'
    'cronie' # cron tasks server
    'dhcpcd'
    'dialog' # dialog boxes for script
    'discord'
    'dmidecode'
    'dolphin'
    'dosfstools' # fat32 file support
    'drkonqi'
    'exfat-utils' # exfat file support
    'firefox'
    'fuse2'
    'fuse3'
    'fuseiso'
    'gamemode'
    'gimp'
    'git'
    'gnome-keyring'
    'gnu-free-fonts'
    'gptfdisk'
    'grub-customizer'
    'gsfonts'
    'gst-libav'
    'gst-plugins-base'
    'gst-plugins-good'
    'gst-plugins-ugly'
    'gwenview'
    'haveged' # antropy generator
    'htop'
    'jdk-openjdk' # Java 17
    'kate'
    'kcalc'
    'kcharselect'
    'kcron'
    'kde-cli-tools'
    'kde-gtk-config'
    'kdecoration'
    'kdenlive' # video editor
    'kdeplasma-addons'
    'keepassxc' # Local password manager
    'kdialog'
    'kfind'
    'kgamma5'
    'kgpg'
    'khotkeys'
    'kinfocenter'
    'kmenuedit'
    'kmix'
    'konsole'
    'kscreen'
    'kscreenlocker'
    'ksystemlog'
    'ksystemstats'
    'kvantum-qt5'
    'kwin'
    'libdbusmenu-glib'
    'libkscreen'
    'libksysguard'
    'libnewt'
    'libtool'
    'libreoffice-fresh'
    'linux-firmware'
    'linux-tkg-pds'
    'linux-tkg-pds-headers'
    'lutris'
    'lzop'
    'midori'
    'make'
    'milou'
    'nano'
    'ncdu' # tool to view space on disk and how much each folder and file take
    'neofetch' # system information tool
    'networkmanager'
    'nmon' # system monitor
    'notepadqq' # notepad++ version for linux
    'noto-fonts'
    'ntfs-3g' # ntfs file support
    'numlockon' # numlock on on tty
    'nvidia'
    'nvidia-dkms' # for custom kernel
    'obs-studio'
    'openssh'
    'p7zip'
    'pacman-contrib'
    'partitionmanager' # KDE Partition Manager
    'picom'
    'plasma-browser-integration'
    'plasma-desktop'
    'plasma-disks'
    'plasma-integration'
    'plasma-nm'
    'plasma-pa'
    'plasma-systemmonitor'
    'plasma-workspace'
    'plasma-workspace-wallpapers'
    'polkit-kde-agent'
    'postman' # utility to make http requests
    'powerdevil'
    'powerpill'
    'pulseaudio' # sound server
    'pulseaudio-alsa' # also configuration for pulseaudio
    'python'
    'python-pip'
    'qbittorrent'
    'rsync'
    'sddm'
    'sddm-kcm'
    'sdl_ttf'
    'spectacle'
    'speedtest-cli'
    'steam'
    'sudo'
    'systemsettings'
    'traceroute'
    'ttf-bitstream-vera'
    'ttf-dejavu'
    'ttf-fira-code'
    'ttf-font-awesome'
    'ttf-hack'
    'ttf-liberation'
    'ttf-roboto'
    'ttf-ubuntu-font-family'
    'unrar'
    'unzip'
    'usbutils'
    'vim'
    'wget'
    'wine-gecko'
    'wine-mono'
    'wine-tkg-staging-fsync-git'
    'winetricks'
    'xdg-desktop-portal-kde'
    'xdg-user-dirs' # creates user dirs
    'xf86-input-libinput'
    'xorg-fonts-type1'
    'xorg-server'
    'xorg-xinit'
    'zenity' # for wine
    'zeroconf-ioslave'
    'zip'
    'zsh'
    'zsh-syntax-highlighting'
    'zsh-autosuggestions'
)

# install all the packages
for PKG in "${PKGS[@]}"; do
    echo "INSTALLING: ${PKG}"
    sudo pacman -Sy "$PKG" --noconfirm --needed
done

echo -e "\nDone!\n"

# creating the user 
if [ $(whoami) = "root"  ];
then
    [ ! -d "/home/netrunner" ] && useradd -m -g users -G wheel -s /bin/bash netrunner 
    cp -R /root/ArchMatic /home/netrunner/
    echo "--------------------------------------"
    echo "--      Set Password for netrunner  --"
    echo "--------------------------------------"
    echo "netrunner:$password" | chpasswd
    cp /etc/skel/.bash_profile /home/netrunner/
    cp /etc/skel/.bash_logout /home/netrunner/
    cp /etc/skel/.bashrc /home/netrunner/.bashrc
    chown -R netrunner: /home/netrunner
    sed -n '#/home/'"netrunner"'/#,s#bash#zsh#' /etc/passwd
    su - netrunner
    echo "Switched to user mode"
else
	echo "You are already a user proceed with aur installs"
fi

echo "**************************************************"
echo "**        Installing packages from AUR          **"
echo "**************************************************"
echo -e "\nINSTALLING AUR SOFTWARE\n"

# install yay and configuring zsh
echo "CLONING: YAY"
cd ~
git clone "https://aur.archlinux.org/yay.git"
cd ${HOME}/yay
makepkg -si --noconfirm
cd ~
touch "$HOME/.cache/zshhistory"
git clone "https://github.com/ChrisTitusTech/zsh"
git clone --depth=1 https://github.com/romkatv/powerlevel10k.git $HOME/powerlevel10k
ln -s "$HOME/zsh/.zshrc" $HOME/.zshrc

# aur packages list
PKGS=(
    'autojump'
    'dxvk-bin'
    'haruna' # video player
    'mangohud' # Gaming FPS Counter
    'mangohud-common'
    'netdiscover'
    'ttf-ms-fonts'
    'zoom' # video conferences
)

# install the packages
for PKG in "${PKGS[@]}"; do
    yay -S --noconfirm $PKG
done

echo -e "\nDone!\n"

echo "**************************************************"
echo "**            Fully upgrading system            **"
echo "**************************************************"

# upgrading with yay
yay -Syyu --noconfirm
# upgrading with pacman and powerpill
sudo pacman -Sy && sudo powerpill -Su

# configure it with using the archdi config part
# follow ultimate gaming guide and set ip up with script
# install in vm, configure all apps and backup .config folder and replace it with the script
# use konsave to save customization
# follow chris titus tech archmatic for any changes