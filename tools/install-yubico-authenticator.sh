#!/bin/sh
set -e -o pipefail

INSTALL_TMP=$(mktemp -d)

cd "$INSTALL_TMP"

curl --proto '=https' --tlsv1.2 -sSfLO https://developers.yubico.com/yubioath-flutter/Releases/yubico-authenticator-latest-linux.tar.gz
tar -xf yubico-authenticator-latest-linux.tar.gz
rm yubico-authenticator-latest-linux.tar.gz

APP_DIR="$(ls -1)"
INSTALL_DIR="$HOME/.local/share/$APP_DIR"

if [ -e "$INSTALL_DIR" ]
then
    echo "Installation directory $INSTALL_DIR already exists: it will not be overwritten."
    rm -rf "$APP_DIR"
    rmdir "$INSTALL_TMP"
    exit 0
fi

mv "$APP_DIR" "$INSTALL_DIR"

echo "Installed $APP_DIR to $INSTALL_DIR"

cd "$INSTALL_DIR"

./desktop_integration.sh --install
ln -sf $INSTALL_DIR/authenticator $HOME/.local/bin/yubico-authenticator

echo "Installed desktop integration and a yubico-authenticator symlink."

rmdir "$INSTALL_TMP"