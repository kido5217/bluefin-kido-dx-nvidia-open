#!/bin/bash

set -ouex pipefail

### Install packages

# Packages can be installed from any enabled yum repo on the image.
# RPMfusion repos are available by default in ublue main images
# List of rpmfusion packages can be found here:
# https://mirrors.rpmfusion.org/mirrorlist?path=free/fedora/updates/43/x86_64/repoview/index.html&protocol=https&redirect=1

# this installs a package from fedora repos
# dnf5 install -y tmux 

# Use a COPR Example:
#
# dnf5 -y copr enable ublue-os/staging
# dnf5 -y install package
# Disable COPRs so they don't end up enabled on the final image:
# dnf5 -y copr disable ublue-os/staging

#### Example for enabling a System Unit File

#systemctl enable podman.socket

## Dev tools

dnf5 install --assumeyes groupinstall "Development Tools"
dnf5 install --assumeyes install cmake

## CUDA

dnf5 install --assumeyes cuda-devel

## netbird

tee /etc/yum.repos.d/netbird.repo <<EOF
[netbird]
name=netbird
baseurl=https://pkgs.netbird.io/yum/
enabled=1
gpgcheck=0
gpgkey=https://pkgs.netbird.io/yum/repodata/repomd.xml.key
repo_gpgcheck=1
EOF

# Workaround for nerbird bug: https://github.com/netbirdio/netbird/issues/5068
dnf5 download netbird --assumeyes --arch x86_64
rpm -i --noscripts netbird_*_linux_amd64.rpm
rm -f netbird_*_linux_amd64.rpm

tee /etc/systemd/system/netbird.service <<EOF
[Unit]
Description=NetBird mesh network client
ConditionFileIsExecutable=/usr/bin/netbird
After=network.target syslog.target 
[Service]
StartLimitInterval=5
StartLimitBurst=10
ExecStart=/usr/bin/netbird "service" "run" "--log-level" "info" "--daemon-addr" "unix:///var/run/netbird.sock" "--log-file" "/var/log/netbird/client.log"
Restart=always
RestartSec=120
EnvironmentFile=-/etc/sysconfig/netbird
Environment=SYSTEMD_UNIT=netbird
[Install]
WantedBy=multi-user.target
EOF

systemctl enable netbird

## misc software

dnf5 install --assumeyes direnv pwgen the_silver_searcher unar waifu2x-converter-cpp xbanish
dnf5 install --assumeyes yt-dlp yt-dlp+default yt-dlp+secretstorage yt-dlp-fish-completion
dnf5 install --assumeyes libgda libgda-sqlite
dnf5 install --assumeyes blender blender-cuda
dnf5 install --assumeyes gnome-directory-thumbnailer gnome-kra-ora-thumbnailer
dnf5 install --assumeyes nebula
#dnf5 install --assumeyes llama-cpp
#dnf5 install --assumeyes cuda

## Remove tailscale

systemctl disable tailscaled
dnf5 remove --assumeyes tailscale

## Add nix packet manager

# mkdir -p /var/nix

# tee /etc/systemd/system/nix.mount <<EOF
# [Unit]
# Description=Bind mount for /nix
# Before=nix-daemon.service
# [Mount]
# What=/var/nix
# Where=/nix
# Type=none
# Options=bind
# [Install]
# WantedBy=multi-user.target
# EOF

# systemctl enable nix.mount
# dnf5 install --assumeyes nix
# systemctl enable nix-daemon

## Disable mcelog

systemctl disable mcelog
dnf5 remove --assumeyes mcelog

## Purge docker

dnf5 remove --assumeyes docker-ce docker-ce-cli docker-ce-rootless-extras docker-model-plugin docker-compose-plugin docker-buildx-plugin

## Enable docker compatibility for podman

dnf5 install --assumeyes podman-docker podman-compose
echo 'DOCKER_HOST=unix://$XDG_RUNTIME_DIR/podman/podman.sock' >> /etc/environment
touch /etc/containers/nodocker
systemctl enable podman.socket

## Install yaak

export YAAK_VERSION="2026.3.1"
wget https://yaak.app/releases/v${YAAK_VERSION}/rpm-x86_64/yaak-${YAAK_VERSION}-1.x86_64.rpm
rpm -i yaak-${YAAK_VERSION}-1.x86_64.rpm
rm -f yaak-${YAAK_VERSION}-1.x86_64.rpm

## Install patched jetbrains mono

# dnf5 remove --assumeyes jetbrains-mono-fonts-all
# dnf5 -y copr enable che/nerd-fonts
# dnf5 install --assumeyes nerd-fonts
# dnf5 -y copr disable che/nerd-fonts

# export NJB_VERSION="3.4.0"
# export NJB_PATH="/usr/share/fonts/jetbrains-mono-nl-nerd-fonts"

# wget https://github.com/ryanoasis/nerd-fonts/releases/download/v${NJB_VERSION}/JetBrainsMono.zip
# unzip -d JetBrainsMono JetBrainsMono.zip
# mkdir ${NJB_PATH}
# cp JetBrainsMono/JetBrainsMonoNL*.ttf ${NJB_PATH}/
# fc-cache -f -v
# rm -rf JetBrainsMono
# rm -rf JetBrainsMono.zip

## Install mise

dnf5 --assumeyes copr enable jdxcode/mise
dnf5 install --assumeyes mise
dnf5 --assumeyes copr disable jdxcode/mise

## Install pngout

export PNGOUT_VERSION="20200115"
wget https://www.jonof.id.au/files/kenutils/pngout-${PNGOUT_VERSION}-linux.tar.gz
tar -xf pngout-${PNGOUT_VERSION}-linux.tar.gz
cp pngout-${PNGOUT_VERSION}-linux/amd64/pngout /usr/bin/
rm -f pngout-${PNGOUT_VERSION}-linux.tar.gz
rm -rf pngout-${PNGOUT_VERSION}-linux

## Install quickshell

dnf5 --assumeyes copr enable errornointernet/quickshell
dnf5 install --assumeyes quickshell
dnf5 --assumeyes copr disable errornointernet/quickshell

## Update all packages

# dnf5 --assumeyes update

## Remove some gnome extensions

export GNOME_EXT_PATH="/usr/share/gnome-shell/extensions"
rm -rf ${GNOME_EXT_PATH}/'apps-menu@gnome-shell-extensions.gcampax.github.com'
rm -rf ${GNOME_EXT_PATH}/'caffeine@patapon.info'
rm -rf ${GNOME_EXT_PATH}/'dash-to-dock@micxgx.gmail.com'
rm -rf ${GNOME_EXT_PATH}/'launch-new-instance@gnome-shell-extensions.gcampax.github.com'
rm -rf ${GNOME_EXT_PATH}/'search-light@icedman.github.com'
rm -rf ${GNOME_EXT_PATH}/'window-list@gnome-shell-extensions.gcampax.github.com'

## Add wallpaper

WP_PATH="/usr/share/backgrounds/kido"
mkdir -p ${WP_PATH}
cp /ctx/wallpapers/* ${WP_PATH}/

## Cleanup

dnf5 autoremove
dnf5 clean all
