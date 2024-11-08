#!/bin/sh
set -e -o pipefail

# Set up Flathub remotes
flatpak remote-add --if-not-exists --user flathub https://flathub.org/repo/flathub.flatpakrepo
flatpak remote-add --if-not-exists --user --subset=verified flathub-verified https://flathub.org/repo/flathub.flatpakrepo

# Install permissions overrides
OVERRIDES_PATH="$HOME/.local/share/flatpak/overrides/"
mkdir -p "$OVERRIDES_PATH"
cp overrides/* "$OVERRIDES_PATH"

# Install apps that have verified maintainers
flatpak --user install -y flathub-verified \
    com.brave.Browser \
    com.dec05eba.gpu_screen_recorder \
    com.discordapp.Discord \
    com.github.tchx84.Flatseal \
    com.github.zocker_160.SyncThingy \
    com.heroicgameslauncher.hgl \
    com.steamgriddb.SGDBoop \
    fr.handbrake.ghb \
    io.github.flattool.Warehouse \
    io.podman_desktop.PodmanDesktop \
    it.mijorus.gearlever \
    md.obsidian.Obsidian \
    net.lutris.Lutris \
    org.cvfosammmm.Setzer \
    org.gimp.GIMP \
    org.gnome.Shotwell \
    org.inkscape.Inkscape \
    org.kde.okteta \
    org.keepassxc.KeePassXC \
    org.libreoffice.LibreOffice \
    org.mozilla.Thunderbird \
    org.qbittorrent.qBittorrent \
    org.torproject.torbrowser-launcher

if [[ "$XDG_SESSION_DESKTOP" = "gnome" ]]
then
    flatpak --user install -y flathub-verified \
        org.gnome.Totem
else
    flatpak --user install -y flathub-verified \
        io.missioncenter.MissionCenter
fi

# Install other verified apps that I'm less sure about
flatpak --user install -y flathub-verified \
    com.github.ryonakano.reco \
    com.usebottles.bottles \
    net.davidotek.pupgui2 \
    org.freac.freac \
    org.freecadweb.FreeCAD \
    org.kde.kid3

# Install apps from unverified maintainers that are probably trustworthy or low-risk enough
flatpak --user install -y flathub \
    com.spotify.Client \
    io.github.philipk.boilr
