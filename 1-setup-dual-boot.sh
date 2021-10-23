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

echo "***************************************"
echo "**          Network Setup            **"
echo "***************************************"
pacman -S networkmanager dhclient --noconfirm --needed
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
hostnamectl --no-ask-password set-hostname "$username"

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
