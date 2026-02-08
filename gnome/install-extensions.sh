#!/bin/sh
set -e -o pipefail

gnome-extensions disable background-logo@fedorahosted.org
gnome-extensions enable apps-menu@gnome-shell-extensions.gcampax.github.com
gnome-extensions enable places-menu@gnome-shell-extensions.gcampax.github.com
gnome-extensions enable window-list@gnome-shell-extensions.gcampax.github.com

# This displays a confirmation dialog
busctl --user call org.gnome.Shell.Extensions /org/gnome/Shell/Extensions org.gnome.Shell.Extensions InstallRemoteExtension s appindicatorsupport@rgcjonas.gmail.com

gnome-extensions enable appindicatorsupport@rgcjonas.gmail.com

# This displays a confirmation dialog
busctl --user call org.gnome.Shell.Extensions /org/gnome/Shell/Extensions org.gnome.Shell.Extensions InstallRemoteExtension s pip-on-top@rafostar.github.com

gnome-extensions enable pip-on-top@rafostar.github.com
