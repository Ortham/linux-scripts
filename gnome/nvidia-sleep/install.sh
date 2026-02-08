#!/bin/sh
set -e -o pipefail

BIN_DIR=/opt/gnome-nvidia-sleep/bin

mkdir -p "$BIN_DIR"
cp -f suspend-gnome-shell.sh "$BIN_DIR"

sed "s/BIN_DIR/${BIN_DIR//\//\\/}/" gnome-shell-suspend.service > /etc/systemd/system/gnome-shell-resume.service
sed "s/BIN_DIR/${BIN_DIR//\//\\/}/" gnome-shell-resume.service > /etc/systemd/system/gnome-shell-resume.service

systemctl daemon-reload

systemctl enable gnome-shell-suspend.service
systemctl enable gnome-shell-resume.service
