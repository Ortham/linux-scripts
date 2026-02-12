#!/bin/sh
# Needs install.1.sh to have been run first.
set -e

sudo kmodgenca
sudo mokutil --import /etc/pki/akmods/certs/public_key.der

git clone https://github.com/CheariX/silverblue-akmods-keys.git

cd silverblue-akmods-keys
git checkout d8da70db94a78759d0ceca1829eb825c0efd002e

sudo bash setup.sh

sudo rpm-ostree install \
	akmods-keys-0.0.2-8.fc41.noarch.rpm

rm akmods-keys-0.0.2-8.fc41.noarch.rpm

sudo rpm-ostree install \
	libva-nvidia-driver \
	akmod-nvidia \
	xorg-x11-drv-nvidia \
	xorg-x11-drv-nvidia-cuda

# amdgpu is modprobe blacklisted so that the iGPU isn't used if enabled.
sudo rpm-ostree kargs \
	--append=rd.driver.blacklist=nouveau,nova_core \
	--append=modprobe.blacklist=nouveau,nova_core,amdgpu
