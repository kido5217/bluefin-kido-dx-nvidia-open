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

systemctl enable podman.socket

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

dnf5 install --assumeyes direnv the_silver_searcher unar xbanish

## Remove tailscale

systemctl disable tailscaled
dnf5 remove --assumeyes tailscale

## Remove homebrew

rm -rf /var/home/linuxbrew

## Add nix packet manager

mkdir -p /var/nix
tee /etc/systemd/system/nix.mount <<EOF
[Unit]
Description=Bind mount for /nix
Before=nix-daemon.service
[Mount]
What=/var/nix
Where=/nix
Type=none
Options=bind
[Install]
WantedBy=multi-user.target
EOF
systemctl enable --now nix.mount
dnf5 install --assumeyes nix
systemctl enable nix-daemon

## Disable mcelog

systemctl disable mcelog
dnf5 remove --assumeyes mcelog

## Purge docker

dnf5 remove --assumeyes docker-ce docker-ce-cli docker-ce-rootless-extras docker-model-plugin docker-compose-plugin docker-buildx-plugin

## Enable docker compatibility for podman

dnf5 install --assumeyes podman-docker podman-compose
echo "DOCKER_HOST=unix://$XDG_RUNTIME_DIR/podman/podman.sock" >> /etc/environment

## Cleanup

dnf5 clean all
