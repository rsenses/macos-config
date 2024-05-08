#!/bin/bash

# Configure dnf (In order: automatically select fastest mirror, parallel downloads, and disable telemetry)
# fastestmirror=1
printf "%s" "
max_parallel_downloads=10
countme=false
" | sudo tee -a /etc/dnf/dnf.conf

# Setup RPMFusion
sudo dnf install -y https://mirrors.rpmfusion.org/free/fedora/rpmfusion-free-release-"$(rpm -E %fedora)".noarch.rpm https://mirrors.rpmfusion.org/nonfree/fedora/rpmfusion-nonfree-release-"$(rpm -E %fedora)".noarch.rpm
sudo dnf groupupdate core -y

# echo 'Make sure your system has been fully-updated by running "sudo dnf upgrade -y" and reboot it once.'
sudo dnf upgrade -y

#Setting umask to 077
# No one except wheel user and root get read/write files
umask 077
sudo sed -i 's/umask 022/umask 077/g' /etc/bashrc

# Debloat
trafotin_debloat () {
    log "trafotin_debloat"
    local -a trafotin_debloating_stuff
    trafotin_debloating_stuff=(
        "ModemManager"
        "NetworkManager-ssh"
        "abrt*"
        "adcli"
        "alsa-sof-firmware"
        "anaconda*"
        "anthy-unicode"
        "atmel-firmware"
        "avahi"
        "baobab"
        "boost-date-time"
        "brasero-libs"
        "cheese"
        "cyrus-sasl-plain"
        "dos2unix"
        "eog"
        "fedora-bookmarks"
        "fedora-chromium-config"
        "geolite2*"
        "hyperv*"
        "kpartx"
        "libertas-usb8388-firmware"
        "loupe"
        "mailcap"
        "mediawriter"
        "mozilla-filesystem"
        "mtr"
        "nano"
        "nano-default-editor"
        "nmap-ncat"
        "open-vm-tools"
        "openconnect"
        "openvpn"
        "orca"
        "perl*"
        "perl-IO-Socket-SSL"
        "podman"
        "ppp"
        "pptp"
        "qemu-guest-agent"
        "qgnomeplatform"
        "realmd"
        "rsync"
        "samba-client"
        "sane*"
        "simple-scan"
        "snapshot"
        "sos"
        "spice-vdagent"
        "sssd"
        "tcpdump"
        "teamd"
        "thermald"
        "totem"
        "traceroute"
        "trousers"
        "unbound-libs"
        "virtualbox-guest-additions"
        "vpnc"
        "xorg-x11-drv-vmware"
        "yajl"
        "yelp"
        "zd1211-firmware"
    )
    sudo dnf -y rm ${trafotin_debloating_stuff[*]}
}
trafotin_debloat

# Run Updates
sudo dnf autoremove -y
sudo fwupdmgr get-devices
sudo fwupdmgr refresh --force
sudo fwupdmgr get-updates -y
sudo fwupdmgr update -y

# Configure GNOME
gsettings set org.gnome.desktop.interface clock-show-weekday true
gsettings set org.gnome.desktop.peripherals.touchpad tap-to-click true

# Setup Flathub beta and third party packages
sudo fedora-third-party enable
sudo fedora-third-party refresh
flatpak remote-add --if-not-exists flathub-beta https://flathub.org/beta-repo/flathub-beta.flatpakrepo

# Install things I need, top is uncategorized
# Debloat
trafotin_flathub () {
    log "trafotin_flathub"
    local -a trafotin_flathub_install
    trafotin_flathub_install=(
        "org.mozilla.firefox"
        "com.brave.Browser"
        "com.github.finefindus.eyedropper"
        "io.mpv.Mpv"
        "com.transmissionbt.Transmission"
        "com.spotify.Client"
        "com.visualstudio.code"
        "com.anydesk.Anydesk"
        "com.usebruno.Bruno"
        "org.filezillaproject.Filezilla"
    )
    flatpak install -y flathub ${trafotin_flathub_install[*]}
}
trafotin_flathub

# Install RPMs
sudo dnf install -y dnf-plugins-core git lazygit neovim zoxide syncthing ripgrep tmux php composer python-nodeenv sqlite3 zsh-autosuggestions zsh-syntax-highlighting ffmpeg compat-ffmpeg4 pandoc --best --allowerasing

# Install Tailscale
sudo dnf config-manager --add-repo https://pkgs.tailscale.com/stable/fedora/tailscale.repo
sudo dnf install tailscale
sudo systemctl enable --now tailscaled
# Para enlazar: sudo tailscale up
# para ver mi ip: tailscale ip -4

# Install codecs
sudo dnf install gstreamer1-plugins-{bad-\*,good-\*,base} gstreamer1-plugin-openh264 gstreamer1-libav --exclude=gstreamer1-plugins-bad-free-devel -y
sudo dnf install lame\* --exclude=lame-deve -y
sudo dnf group upgrade --allowerasing --with-optional Multimedia -y

# Harden the Kernel with Kicksecure's patches
# Disables CD ROMs, FireWire, default writes, various kernel flags.
sudo curl https://raw.githubusercontent.com/Kicksecure/security-misc/master/etc/modprobe.d/30_security-misc.conf -o /etc/modprobe.d/30_security-misc.conf
sudo curl https://raw.githubusercontent.com/Kicksecure/security-misc/master/etc/sysctl.d/30_security-misc.conf -o /etc/sysctl.d/30_security-misc.conf
sudo curl https://raw.githubusercontent.com/Kicksecure/security-misc/a9886a3119f9b662b15fc26d28a7fedf316b72c4/usr/lib/sysctl.d/30_silent-kernel-printk.conf -o /etc/sysctl.d/30_silent-kernel-printk.conf

# Enable Kicksecure CPU mitigations
sudo curl https://raw.githubusercontent.com/Kicksecure/security-misc/master/etc/default/grub.d/40_cpu_mitigations.cfg -o /etc/grub.d/40_cpu_mitigations.cfg
# Kicksecure's CPU distrust script
sudo curl https://raw.githubusercontent.com/Kicksecure/security-misc/master/etc/default/grub.d/40_distrust_cpu.cfg -o /etc/grub.d/40_distrust_cpu.cfg
# Enable Kicksecure's IOMMU patch (limits DMA)
# New url (2024-04-18): https://github.com/Kicksecure/security-misc/raw/a9886a3119f9b662b15fc26d28a7fedf316b72c4/etc/default/grub.d/40_enable_iommu.cfg
sudo curl https://raw.githubusercontent.com/Kicksecure/security-misc/master/etc/default/grub.d/40_enable_iommu.cfg -o /etc/grub.d/40_enable_iommu.cfg

# Divested's brace patches
# Sandbox the brace systemd permissions
# If you have VPN issues: https://old.reddit.com/r/DivestOS/comments/12b4fk4/comment/jex4qt2/
sudo mkdir -p /etc/systemd/system/NetworkManager.service.d
sudo curl https://gitlab.com/divested/brace/-/raw/master/brace/usr/lib/systemd/system/NetworkManager.service.d/99-brace.conf -o /etc/systemd/system/NetworkManager.service.d/99-brace.conf
sudo mkdir -p /etc/systemd/system/irqbalance.service.d
sudo curl https://gitlab.com/divested/brace/-/raw/master/brace/usr/lib/systemd/system/irqbalance.service.d/99-brace.conf -o /etc/systemd/system/irqbalance.service.d/99-brace.conf

# GrapheneOS's ssh limits
# caps the system usage of sshd
sudo mkdir -p /etc/systemd/system/sshd.service.d
sudo curl https://raw.githubusercontent.com/GrapheneOS/infrastructure/main/systemd/system/sshd.service.d/local.conf -o /etc/systemd/system/sshd.service.d/local.conf
# echo "GSSAPIAuthentication no" | sudo tee /etc/ssh/ssh_config.d/10-custom.conf
# echo "VerifyHostKeyDNS yes" | sudo tee -a /etc/ssh/ssh_config.d/10-custom.conf

# NTS instead of NTP
# NTS is a more secured version of NTP
sudo curl https://raw.githubusercontent.com/GrapheneOS/infrastructure/main/chrony.conf -o /etc/chrony.conf

# Whonix Machine ID
echo "b08dfa6083e7567a1921a715000001fb" | sudo tee /etc/machine-id

# Remove Firewalld's Default Rules
sudo firewall-cmd --permanent --remove-port=1025-65535/udp
sudo firewall-cmd --permanent --remove-port=1025-65535/tcp
sudo firewall-cmd --permanent --remove-service=mdns
sudo firewall-cmd --permanent --remove-service=ssh
sudo firewall-cmd --permanent --remove-service=samba-client
sudo firewall-cmd --reload

#Randomize MAC address and disable static hostname. This could be used to track general network activity.
sudo bash -c 'cat > /etc/NetworkManager/conf.d/00-macrandomize.conf' <<-'EOF'
[main]
hostname-mode=none

[device]
wifi.scan-rand-mac-address=yes

[connection]
wifi.cloned-mac-address=random
ethernet.cloned-mac-address=random
EOF

sudo systemctl restart NetworkManager
sudo hostnamectl hostname "localhost"

# Make the Home folder private
# Privatizing the home folder creates problems with virt-manager
# accessing ISOs from your home directory. Store images in /var/lib/libvirt/images
chmod 700 /home/"$(whoami)"
# is reset using:
#chmod 755 /home/"$(whoami)"

echo "The configuration is now complete."
