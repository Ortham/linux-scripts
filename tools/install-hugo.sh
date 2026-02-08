#!/bin/sh
set -e -o pipefail

HUGO_VERSION=0.155.2
HUGO_HASH=a680e2c6dd0e2244c237c85b549cb8697778cd068c84af1f7b0d9422827a554c

curl --proto '=https' --tlsv1.2 -sSfLO https://github.com/gohugoio/hugo/releases/download/v${HUGO_VERSION}/hugo_${HUGO_VERSION}_linux-amd64.tar.gz
echo "$HUGO_HASH hugo_${HUGO_VERSION}_linux-amd64.tar.gz" | sha256sum -c

tar -xf hugo_${HUGO_VERSION}_linux-amd64.tar.gz -C ~/.local/bin/ hugo
