#!/bin/sh
set -e -o pipefail

cp -f notify-syncthing-conflicts.sh "$HOME/.local/bin/"

cp -f syncthing-conflict-detector.service "$HOME/.config/systemd/user/"

systemctl --user enable syncthing-conflict-detector.service

systemctl --user start syncthing-conflict-detector.service
