#!/bin/bash
# ---------------------------
# This is a bash script for configuring Debian 12 (bookworm) for pro audio.
# ---------------------------
# NOTE: Execute this script by running the following command on your system:
# wget -O ~/install-audio.sh https://raw.githubusercontent.com/brendaningram/linux-audio-setup-scripts/main/debian/11/install-audio-jack.sh && chmod +x ~/install-audio.sh && ~/install-audio.sh




# ---------------------------
#  1 Update our system
# ---------------------------

sudo apt update && sudo apt dist-upgrade -y


# ---------------------------
# 2 Install Liquorix kernel
# https://liquorix.net/
# ---------------------------

sudo apt install curl -y
curl 'https://liquorix.net/add-liquorix-repo.sh' | sudo bash
sudo apt install linux-image-liquorix-amd64 linux-headers-liquorix-amd64 -y


# ---------------------------
# 3 Install kxstudio and cadence
# Cadence is a tool for managing audio connections to our hardware
# NOTE: Select "YES" when asked to enable realtime privileges
# ---------------------------

sudo apt install apt-transport-https gpgv wget -y
wget https://launchpad.net/~kxstudio-debian/+archive/kxstudio/+files/kxstudio-repos_11.1.0_all.deb
sudo dpkg -i kxstudio-repos_11.1.0_all.deb
rm kxstudio-repos_11.1.0_all.deb
sudo apt update
sudo apt install cadence -y


# ---------------------------
# 4 grub
# ---------------------------

sudo sed -i 's/GRUB_CMDLINE_LINUX_DEFAULT="quiet"/GRUB_CMDLINE_LINUX_DEFAULT="quiet threadirqs mitigations=off cpufreq.default_governor=performance"/g' /etc/default/grub
sudo update-grub

# ---------------------------
# 5 limits
# See https://wiki.linuxaudio.org/wiki/system_configuration for more information.
# ---------------------------

echo '@audio - rtprio 90
@audio - memlock unlimited' | sudo tee -a /etc/security/limits.d/audio.conf


# ---------------------------
# 5 sysctl.conf
# ---------------------------
# See https://wiki.linuxaudio.org/wiki/system_configuration for more information.

echo 'vm.swappiness=10
fs.inotify.max_user_watches=600000' | sudo tee -a /etc/sysctl.conf


# ---------------------------
# 6 Add the user to the audio group
# ---------------------------
notify "Add user to the audio group"
sudo usermod -a -G audio $USER


# ---------------------------
# 7 REAPER
# Note: The instructions below will create a PORTABLE REAPER installation
# at ~/REAPER.
# ---------------------------
notify "REAPER"
wget -O reaper.tar.xz http://reaper.fm/files/6.x/reaper679_linux_x86_64.tar.xz
mkdir ./reaper
tar -C ./reaper -xf reaper.tar.xz
./reaper/reaper_linux_x86_64/install-reaper.sh --install ~/ --integrate-desktop
rm -rf ./reaper
rm reaper.tar.xz
touch ~/REAPER/reaper.ini


# ---------------------------
# 8 Wine (staging)
# This is required for yabridge
# See https://wiki.winehq.org/Debian for additional information.
# ---------------------------

sudo dpkg --add-architecture i386
sudo mkdir -pm755 /etc/apt/keyrings
sudo wget -O /etc/apt/keyrings/winehq-archive.key https://dl.winehq.org/wine-builds/winehq.key
sudo wget -NP /etc/apt/sources.list.d/ https://dl.winehq.org/wine-builds/debian/dists/bookworm/winehq-bookworm.sources
sudo apt update
sudo apt install --install-recommends winehq-staging -y

# ---------------------------
# 9 Winetricks
# ---------------------------


sudo apt install cabextract -y
mkdir -p ~/.local/share
wget -O winetricks https://raw.githubusercontent.com/Winetricks/winetricks/master/src/winetricks
mv winetricks ~/.local/share
chmod +x ~/.local/share/winetricks
echo '' >> ~/.bash_aliases
echo '# Audio: winetricks' >> ~/.bash_aliases
echo 'export PATH="$PATH:$HOME/.local/share"' >> ~/.bash_aliases
. ~/.bash_aliases

# Base wine packages required for proper plugin functionality
winetricks corefonts 
#winetricks allfonts
winetricks vcrun6sp6
winetricks vcrun2013
winetricks vcrun2015
winetricks wininet
winetricks gdiplus

# Make a copy of .wine, as we will use this in the future as the base of
# new wine prefixes (when installing plugins)
cp -r ~/.wine ~/.wine-base


# ---------------------------
# Yabridge
# can be found at: https://github.com/robbert-vdh/yabridge/blob/master/README.md
# ---------------------------
# NOTE: CHECK YABRIDGNE VERSION @ https://github.com/robbert-vdh/yabridge/releases

wget -O yabridge.tar.gz https://github.com/robbert-vdh/yabridge/releases/download/5.0.5/yabridge-5.0.5.tar.gz
mkdir -p ~/.local/share
tar -C ~/.local/share -xavf yabridge.tar.gz
rm yabridge.tar.gz
echo '' >> ~/.bash_aliases
echo '# Audio: yabridge path' >> ~/.bash_aliases
echo 'export PATH="$PATH:$HOME/.local/share/yabridge"' >> ~/.bash_aliases
. ~/.bash_aliases

# libnotify-bin contains notify-send, which is used for yabridge plugin notifications.
sudo apt install libnotify-bin -y

# Create common VST paths
mkdir -p "$HOME/.wine/drive_c/Program Files/Steinberg/VstPlugins"
mkdir -p "$HOME/.wine/drive_c/Program Files/Common Files/VST2"
mkdir -p "$HOME/.wine/drive_c/Program Files/Common Files/VST3"

# Add them into yabridge
yabridgectl add "$HOME/.wine/drive_c/Program Files/Steinberg/VstPlugins"
yabridgectl add "$HOME/.wine/drive_c/Program Files/Common Files/VST2"
yabridgectl add "$HOME/.wine/drive_c/Program Files/Common Files/VST3"

# ---------------------------
# Install Windows VST plugins
# This is a manual step for you to run when you download plugins.
# First, run the plugin installer .exe file
# When the installer asks for a directory, make sure you select
# one of the directories above.

# VST2 plugins:
#   C:\Program Files\Steinberg\VstPlugins
# OR
#   C:\Program Files\Common Files\VST2

# VST3 plugins:
#   C:\Program Files\Common Files\VST3
# ---------------------------

# Each time you install a new plugin, you need to run:
# yabridgectl sync

# ---------------------------
# FINISHED!
# Now just reboot, and make music!
