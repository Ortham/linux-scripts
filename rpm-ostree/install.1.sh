#!/bin/sh
set -e

# akmods and rpmdevtools are needed to run the silverblue-akmods-keys script
# that's used to support Secure Boot with the proprietary Nvidia driver.
# ksshaskpass is needed for SSH key passphrase / PIN prompts.
# inotify-tools is needed by the syncthing-conflict-detector provided by this
# repository.
# lm_sensors isn't strictly necessary for anything but helps when viewing
# hardware sensor data.
sudo rpm-ostree install \
	https://mirrors.rpmfusion.org/free/fedora/rpmfusion-free-release-$(rpm -E %fedora).noarch.rpm \
	https://mirrors.rpmfusion.org/nonfree/fedora/rpmfusion-nonfree-release-$(rpm -E %fedora).noarch.rpm \
	akmods \
    distrobox \
	flatpak-builder \
    ksshaskpass \
	inotify-tools \
	lm_sensors \
	restic \
	rpmdevtools \
    vim
