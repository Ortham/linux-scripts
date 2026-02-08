#!/bin/sh
set -e -o pipefail

UV_VERSION=0.10.0
UV_HASH=230e328948c92dd1ebad83949c4d56e83813dfe9c6362a4c519e6a227973f1ae

curl --proto '=https' --tlsv1.2 -sSfLO https://github.com/astral-sh/uv/releases/download/${UV_VERSION}/uv-x86_64-unknown-linux-gnu.tar.gz
echo "$UV_HASH uv-x86_64-unknown-linux-gnu.tar.gz" | sha256sum -c

tar -xf uv-x86_64-unknown-linux-gnu.tar.gz -C ~/.local/bin/ --strip-components=1
