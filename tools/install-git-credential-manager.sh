#!/bin/sh
set -e -o pipefail

GCM_VERSION=2.7.0
GCM_HASH=61b7370ba82525fc812e0c86f3d41cc0dc0cb7388fe9e78e53af941d5c94c28f

curl --proto '=https' --tlsv1.2 -sSfLO https://github.com/git-ecosystem/git-credential-manager/releases/download/v${GCM_VERSION}/gcm-linux-x64-${GCM_VERSION}.tar.gz
echo "$GCM_HASH gcm-linux-x64-${GCM_VERSION}.tar.gz" | sha256sum -c

tar -xf gcm-linux-x64-${GCM_VERSION}.tar.gz -C ~/.local/bin/ git-credential-manager libHarfBuzzSharp.so libSkiaSharp.so

git config set --global credential.credentialStore secretservice
git-credential-manager configure
