# creating the user 
if [ $(whoami) = "root"  ];
then
    [ ! -d "/home/$username" ] && useradd -m -g users -G wheel -s /bin/bash $username 
    cp -R /root/ArchMatic /home/$username/
    echo "--------------------------------------"
    echo "--      Set Password for $username  --"
    echo "--------------------------------------"
    echo "$username:$password" | chpasswd
    cp /etc/skel/.bash_profile /home/$username/
    cp /etc/skel/.bash_logout /home/$username/
    cp /etc/skel/.bashrc /home/$username/.bashrc
    chown -R $username: /home/$username
    sed -n '#/home/'"$username"'/#,s#bash#zsh#' /etc/passwd
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
su $username -c "cd ~"
git clone "https://aur.archlinux.org/yay.git"
su $username -c "cd ~/yay"
su $username -c "makepkg -si --noconfirm"
su $username -c "cd ~"
su $username -c "touch ~/.cache/zshhistory"
git clone "https://github.com/ChrisTitusTech/zsh"
git clone --depth=1 https://github.com/romkatv/powerlevel10k.git ~/powerlevel10k
ln -s "~/zsh/.zshrc" ~/.zshrc

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
    su $username -c "yay -S --noconfirm $PKG"
done

echo -e "\nDone!\n"

echo "**************************************************"
echo "**            Fully upgrading system            **"
echo "**************************************************"

# upgrading with yay
su $username -c "yay -Syyu --noconfirm"
# upgrading with pacman and powerpill
sudo pacman -Sy && sudo powerpill -Su
