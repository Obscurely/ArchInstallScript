echo "**************************************************"
echo "**               Configuring bash               **"
echo "**************************************************"
# set default editor
echo "export EDITOR=nano" > /etc/profile.d/editor.sh
  chmod 755 /etc/profile.d/editor.sh
  export EDITOR=nano

# set aliases
echo "alias ls='ls --color=auto'" >> /etc/profile.d/alias.sh
echo "alias l='ls --color=auto -lA'" >> /etc/profile.d/alias.sh
echo "alias ll='ls --color=auto -l'" >> /etc/profile.d/alias.sh
echo "alias cd..='cd ..'" >> /etc/profile.d/alias.sh
echo "alias ..='cd ..'" >> /etc/profile.d/alias.sh
echo "alias ...='cd ../../'" >> /etc/profile.d/alias.sh
echo "alias ....='cd ../../../'" >> /etc/profile.d/alias.sh
echo "alias .....='cd ../../../../'" >> /etc/profile.d/alias.sh
echo "alias ff='find / -name'" >> /etc/profile.d/alias.sh
echo "alias f='find . -name'" >> /etc/profile.d/alias.sh
echo "alias grep='grep --color=auto'" >> /etc/profile.d/alias.sh
echo "alias egrep='egrep --color=auto'" >> /etc/profile.d/alias.sh
echo "alias fgrep='fgrep --color=auto'" >> /etc/profile.d/alias.sh
echo "alias ip='ip -c'" >> /etc/profile.d/alias.sh
echo "alias pacman='pacman --color auto'" >> /etc/profile.d/alias.sh
echo "alias pactree='pactree --color'" >> /etc/profile.d/alias.sh
echo "alias vdir='vdir --color=auto'" >> /etc/profile.d/alias.sh
echo "alias watch='watch --color'" >> /etc/profile.d/alias.sh

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


# enable login dispaly manager
udo systemctl enable --now sddm.service


echo -e "\nSetup SDDM Theme"

sudo cat <<EOF > /etc/sddm.conf.d/kde_settings.conf
[Autologin]
Relogin=false
Session=
User=
[General]
HaltCommand=/usr/bin/systemctl poweroff
RebootCommand=/usr/bin/systemctl reboot
[Theme]
Current=Nordic
[Users]
MaximumUid=60513
MinimumUid=1000
EOF

# Remove no password sudo rights
sed -i 's/^%wheel ALL=(ALL) NOPASSWD: ALL/# %wheel ALL=(ALL) NOPASSWD: ALL/' /etc/sudoers
# Add sudo rights
sed -i 's/^# %wheel ALL=(ALL) ALL/%wheel ALL=(ALL) ALL/' /etc/sudoers

# Replace in the same state
su $username -c "cd $pwd"


echo "Applying gaming tweaks!"
# package list to install
PKGS=(
'auto-cpufreq'
'vkBasalt'
'earlyoom'
'ananicy-git'
'libva-vdpau-driver'
'goverlay'
)

# creating a temp dir
cd /home/$(whoami)/Documents/
mkdir temp

# updating pacman database
pacman -Syy --noconfirm 

# installs the latest nvidia driver with tkg patches.
git clone https://github.com/Frogging-Family/nvidia-all.git
cd nvidia-all
su $username -c "makepkg -si"

cd ..

# installing the package list
for PKG in "${PKGS[@]}"; do
    echo "INSTALLING: ${PKG}"
    sudo pacman -S "$PKG" --noconfirm --needed
done

# enable and tweak some services
echo -e "\nEnableing Services and Tweaking\n"

systemctl --user enable gamemoded && systemctl --user start gamemoded
systemctl enable --now earlyoom

# grauda linux performance tweaks package
git clone https://gitlab.com/garuda-linux/themes-and-settings/settings/performance-tweaks.git
cd performance-tweaks
su $username -c "makepkg -si --noconfirm"

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
su $username -c "cd ~"
git clone https://github.com/ChrisTitusTech/ArchMatic.git
su $username -c "export PATH=$PATH:~/.local/bin"
su $username -c "cp -r ~/ArchMatic/dotfiles/* ~/.config/"
pip install konsave
konsave -i $HOME/ArchMatic/kde.knsv
sleep 1
konsave -a kde

# Setup UFW rules
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
