#!/bin/bash
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
    com.discordapp.Discord \
    com.github.tchx84.Flatseal \
    com.github.zocker_160.SyncThingy \
    com.heroicgameslauncher.hgl \
    com.steamgriddb.SGDBoop \
    fr.handbrake.ghb \
    io.ente.photos \
    io.podman_desktop.PodmanDesktop \
    it.mijorus.gearlever \
    md.obsidian.Obsidian \
    net.lutris.Lutris \
    org.gimp.GIMP \
    org.inkscape.Inkscape \
    org.kde.kdiff3 \
    org.kde.kleopatra \
    org.kde.okteta \
    org.keepassxc.KeePassXC \
    org.libreoffice.LibreOffice \
    org.mozilla.Thunderbird \
    org.qbittorrent.qBittorrent

# Install apps from unverified maintainers that are probably trustworthy or low-risk enough
flatpak --user install -y flathub \
    com.spotify.Client

ASK_VERIFIED_FLATPAKS=(
    com.dec05eba.gpu_screen_recorder
    com.github.ryonakano.reco
    com.usebottles.bottles
    io.github.flattool.Warehouse
    io.github.Qalculate
    org.cvfosammmm.Setzer
    net.davidotek.pupgui2
    org.gnome.Shotwell
    net.nokyan.Resources
    org.freac.freac
    org.freecad.FreeCAD
    org.kde.kid3
    org.texstudio.TeXstudio
    org.virt_manager.virt-manager
)

if [ "$XDG_SESSION_DESKTOP" = "gnome" ]
then
    ASK_VERIFIED_FLATPAKS+=(org.gnome.Totem)
else
    ASK_VERIFIED_FLATPAKS+=(io.missioncenter.MissionCenter)
fi

ASK_UNVERIFIED_FLATPAKS=(
    io.github.philipk.boilr
)

ask_install() {
    TARGET="$1"

    read -p "Do you want to install $TARGET? (y/N) " answer
    case "$answer" in
        [yY]* )
            return 0
            ;;
        * )
            return 1
            ;;
    esac
}

for FLATPAK_ID in "${ASK_VERIFIED_FLATPAKS[@]}"
do
    if ask_install "$FLATPAK_ID"
    then
        flatpak --user install -y flathub-verified "$FLATPAK_ID"
    fi
done

for FLATPAK_ID in "${ASK_UNVERIFIED_FLATPAKS[@]}"
do
    if ask_install "$FLATPAK_ID (unverified!)"
    then
        flatpak --user install -y flathub "$FLATPAK_ID"
    fi
done

# Build and install my Variety fork as a Flatpak
if ask_install "Variety as a Flatpak"
then
    VARIETY_DIR="$(mktemp -d -p /var/tmp -t "variety.XXXXXXXXXX")"
    git clone https://github.com/Ortham/variety.git "$VARIETY_DIR"
    cd "$VARIETY_DIR"
    git checkout flatpak
    git submodule init
    git submodule update
    ./flatpak-resources/generate-manifests.sh
    ./flatpak-resources/build-flatpak.sh
fi
