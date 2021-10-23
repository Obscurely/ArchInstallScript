echo "**************************************************"
echo "**                                              **"
echo "*   Arch DE Configuration (script part 2 of 2)   *"
echo "**                                              **"
echo "**************************************************"

echo "**************************************************"
echo "**       Installing packages from pacman        **"
echo "**************************************************"
# enabling chaotic-aur
sudo pacman-key --recv-key 3056513887B78AEB --keyserver keyserver.ubuntu.com
sudo pacman-key --lsign-key 3056513887B78AEB
sudo pacman -U 'https://cdn-mirror.chaotic.cx/chaotic-aur/chaotic-keyring.pkg.tar.zst' 'https://cdn-mirror.chaotic.cx/chaotic-aur/chaotic-mirrorlist.pkg.tar.zst' --noconfirm
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