#!/bin/sh
set -e -o pipefail

cd backup/restic
sudo ./install.sh
cd -

cd flatpak
./install.sh
cd -

if [ "$XDG_SESSION_DESKTOP" = "gnome" ]
then
	cd gnome/nvidia-sleep
	sudo ./install.sh
	cd ..
	./install-extensions.sh
	cd ..
fi

cd kernel
./configure-kernel-modules.sh
cd -

cd syncthing
./install.sh
cd -

cd tools
./install-git-credential-manager.sh
./install-hugo.sh
./install-uv.sh
./install-yubico-authenticator.sh
cd -
