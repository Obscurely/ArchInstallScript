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
    'alsa-lib'
    'alsa-plugins' # extra alsa plugins
    'alsa-utils' # sound support
    'amd-ucode'
    'ark'
    'audiocd-kio' 
    'base'
    'base-devel'
    'bash-completion'
    'bind'
    'binutils'
    'bleachbit' # Profile Cleaner
    'breeze'
    'breeze-gtk'
    'btrfs-progs' # brtfs file utils
    'clementine'
    'code'
    'cronie' # cron tasks server
    'dbus'
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
    'giflib'
    'gimp'
    'git'
    'gnome-keyring'
    'gnu-free-fonts'
    'gnutls'
    'gptfdisk'
    'grub-customizer'
    'gtk3'
    'gsfonts'
    'gst-libav'
    'gst-plugins-base'
    'gst-plugins-base-libs'
    'gst-plugins-good'
    'gst-plugins-ugly'
    'gwenview'
    'haveged' # antropy generator
    'htop'
    'iptables'
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
    'kitty'
    'kmenuedit'
    'kmix'
    'konsole'
    'kscreen'
    'kscreenlocker'
    'ksystemlog'
    'ksystemstats'
    'kvantum-qt5'
    'kwin'
    'lib32-alsa-lib'
    'lib32-alsa-plugins'
    'lib32-giflib'
    'lib32-libpng'
    'lib32-libldap'
    'lib32-gnutls'
    'lib32-mpg123'
    'lib32-openal'
    'lib32-v4l-utils'
    'lib32-libpulse'
    'lib32-libgpg-error'
    'lib32-libjpeg-turbo'
    'lib32-sqlite'
    'lib32-libxcomposite'
    'lib32-libgcrypt'
    'lib32-libxinerama'
    'lib32-ncurses'
    'lib32-opencl-icd-loader'
    'lib32-libxslt'
    'lib32-libva'
    'lib32-gtk3'
    'lib32-gst-plugins-base-libs'
    'lib32-vulkan-icd-loader'
    'libjpeg-turbo'
    'libdbusmenu-glib'
    'libgpg-error'
    'libkscreen'
    'libksysguard'
    'libldap'
    'libnewt'
    'libpng'
    'libpulse'
    'libtool'
    'libxcomposite'
    'libxinerama'
    'libva'
    'libgcrypt'
    'libxslt'
    'libreoffice-fresh'
    'linux-firmware'
    'linux-tkg-pds'
    'linux-tkg-pds-headers'
    'lutris'
    'lzop'
    'midori'
    'make'
    'meson'
    'milou'
    'mpg123'
    'nano'
    'ncdu' # tool to view space on disk and how much each folder and file take
    'ncurses'
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
    'openal'
    'opencl-icd-loader'
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
    'powerline-fonts'
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
    'sqlite'
    'steam'
    'sudo'
    'swtpm'
    'systemd'
    'systemsettings'
    'terminus-font'
    'traceroute'
    'ttf-bitstream-vera'
    'ttf-dejavu'
    'ttf-fira-code'
    'ttf-font-awesome'
    'ttf-hack'
    'ttf-liberation'
    'ttf-roboto'
    'ttf-ubuntu-font-family'
    'ufw'
    'unrar'
    'unzip'
    'usbutils'
    'v4l-utils'
    'vim'
    'vulkan-icd-loader'
    'wget'
    'which'
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
    'awesome-terminal-fonts'
    'dxvk-bin'
    'haruna' # video player
    'lightly-git'
    'lightlyshaders-git'
    'mangohud' # Gaming FPS Counter
    'mangohud-common'
    'netdiscover'
    'nordic-darker-standard-buttons-theme'
    'nordic-darker-theme'
    'nordic-kde-git'
    'nordic-theme'
    'noto-fonts-emoji'
    'papirus-icon-theme'
    'sddm-nordic-theme-git'
    'ocs-url' # install packages from websites
    'timeshift-bin'
    'ttf-droid'
    'ttf-hack'
    'ttf-meslo' # Nerdfont package
    'ttf-ms-fonts'
    'ttf-roboto'
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

echo "**************************************************"
echo "**               Configuring bash               **"
echo "**************************************************"
# set default editor
echo "export EDITOR=nano" > /etc/profile.d/editor.sh
  chmod 755 /etc/profile.d/editor.sh
  export EDITOR=nano

# set aliases
echo "alias ls='ls --color=auto'" >> /etc/profile.d/alias.sh;;
echo "alias l='ls --color=auto -lA'" >> /etc/profile.d/alias.sh;;
echo "alias ll='ls --color=auto -l'" >> /etc/profile.d/alias.sh;;
echo "alias cd..='cd ..'" >> /etc/profile.d/alias.sh;;
echo "alias ..='cd ..'" >> /etc/profile.d/alias.sh;;
echo "alias ...='cd ../../'" >> /etc/profile.d/alias.sh;;
echo "alias ....='cd ../../../'" >> /etc/profile.d/alias.sh;;
echo "alias .....='cd ../../../../'" >> /etc/profile.d/alias.sh;;
echo "alias ff='find / -name'" >> /etc/profile.d/alias.sh;;
echo "alias f='find . -name'" >> /etc/profile.d/alias.sh;;
echo "alias grep='grep --color=auto'" >> /etc/profile.d/alias.sh;;
echo "alias egrep='egrep --color=auto'" >> /etc/profile.d/alias.sh;;
echo "alias fgrep='fgrep --color=auto'" >> /etc/profile.d/alias.sh;;
echo "alias ip='ip -c'" >> /etc/profile.d/alias.sh;;
echo "alias pacman='pacman --color auto'" >> /etc/profile.d/alias.sh;;
echo "alias pactree='pactree --color'" >> /etc/profile.d/alias.sh;;
echo "alias vdir='vdir --color=auto'" >> /etc/profile.d/alias.sh;;
echo "alias watch='watch --color'" >> /etc/profile.d/alias.sh;;

# set ps1
cat > /etc/profile.d/ps1.sh << "EOF"
#!/bin/bash
clrreset='\e[0m'
clrwhite='\e[1;37m'
clrgreen='\e[1;32m'
clrred='\e[1;31m'
export PS1="\[$clrwhite\]\w \`if [ \$? = 0 ]; then echo -e '\[$clrgreen\]'; else echo -e '\[$clrred\]'; fi\`\\$ \[$clrreset\]"
EOF
chmod 755 /etc/profile.d/ps1.sh
;;

echo "**************************************************"
echo "**            Configuring rest of Arch          **"
echo "**************************************************"
# Generate x.initrc file so we can launch Awesome from the terminal using the startx command
cat <<EOF > ${HOME}/.xinitrc
#!/bin/bash
# Disable bell
xset -b
# Disable all Power Saving Stuff
xset -dpms
xset s off
# X Root window color
xsetroot -solid darkgrey
# Merge resources (optional)
#xrdb -merge $HOME/.Xresources
# Caps to Ctrl, no caps
setxkbmap -layout us -option ctrl:nocaps
if [ -d /etc/X11/xinit/xinitrc.d ] ; then
    for f in /etc/X11/xinit/xinitrc.d/?*.sh ; do
        [ -x "\$f" ] && . "\$f"
    done
    unset f
fi
exit 0
EOF

# increase file watcher count
# this prevents a "too many files" error in Visual Studio Code
echo fs.inotify.max_user_watches=524288 | sudo tee /etc/sysctl.d/40-max-user-watches.conf && sudo sysctl --system

# Pulse audio loads the `esound-protocol` module, which best I can tell is rarely needed.
# That module creates a file called `.esd_auth` in the home directory which I'd prefer to not be there. So...
sudo sed -i 's|load-module module-esound-protocol-unix|#load-module module-esound-protocol-unix|g' /etc/pulse/default.pa

# enable login display manager
sudo systemctl enable --now sddm.service

# Remove no password sudo rights
sed -i 's/^%wheel ALL=(ALL) NOPASSWD: ALL/# %wheel ALL=(ALL) NOPASSWD: ALL/' /etc/sudoers
# Add sudo rights
sed -i 's/^# %wheel ALL=(ALL) ALL/%wheel ALL=(ALL) ALL/' /etc/sudoers

# Replace in the same state
cd $pwd


echo "Applying gaming tweaks!"
# package list to install
PKGS=(
'auto-cpufreq'
'vkBasalt'
'earlyoom'
'ananicy-git'
'libva-vdpau-driver'
)

# creating a temp dir
cd /home/$(whoami)/Documents/
mkdir temp

# updating pacman database
pacman -Syy --noconfirm 

# installs the latest nvidia driver with tkg patches.
git clone https://github.com/Frogging-Family/nvidia-all.git
cd nvidia-all
makepkg -si
;;

# installing the package list
for PKG in "${PKGS[@]}"; do
    echo "INSTALLING: ${PKG}"
    sudo pacman -S "$PKG" --noconfirm --needed
done

# enable and tweak some services
echo -e "\nEnableing Services and Tweaking\n"

systemctl --user enable gamemoded && systemctl --user start gamemoded
systemctl enable --now earlyoom

sudo sysctl -w net.core.netdev_max_backlog = 16384
sudo sysctl -w net.core.somaxconn = 8192
sudo sysctl -w net.core.rmem_default = 1048576
sudo sysctl -w net.core.rmem_max = 16777216
sudo sysctl -w net.core.wmem_default = 1048576
sudo sysctl -w net.core.wmem_max = 16777216
sudo sysctl -w net.core.optmem_max = 65536
sudo sysctl -w net.ipv4.tcp_rmem = 4096 1048576 2097152
sudo sysctl -w net.ipv4.tcp_wmem = 4096 65536 16777216
sudo sysctl -w net.ipv4.udp_rmem_min = 8192
sudo sysctl -w net.ipv4.udp_wmem_min = 8192
sudo sysctl -w net.ipv4.tcp_fastopen = 3
sudo sysctl -w net.ipv4.tcp_max_syn_backlog = 8192
sudo sysctl -w net.ipv4.tcp_max_tw_buckets = 2000000
sudo sysctl -w vm.swappiness = 10

# delete temp dir
rm -rf /home/$(whoami)/Documents/temp

# Applying customization from ChrisTitusTech's ArchMatic fork
cd ~
git clone https://github.com/ChrisTitusTech/ArchMatic.git
export PATH=$PATH:~/.local/bin
cp -r $HOME/ArchMatic/dotfiles/* $HOME/.config/
pip install konsave
konsave -i $HOME/ArchMatic/kde.knsv
sleep 1
konsave -a kde

# Securing arch
# --- Setup UFW rules
sudo ufw limit 22/tcp  
sudo ufw allow 80/tcp  
sudo ufw allow 443/tcp  
sudo ufw default deny incoming  
sudo ufw default allow outgoing
sudo ufw enable

# Done installed arch linux
echo "DONE!!! Press enter to reboot!"
read ans
reboot now