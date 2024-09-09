#!/bin/sh
# Backup script using Kopia.
set -e

SYNC_PARALLELISM=10

SOURCE_PATH="/"
LOCAL_BACKUP_CONFIG="/root/.config/kopia/local-repository.config"
REMOTE_BACKUP_CONFIG="/root/.config/kopia/remote-repository.config"

echo "Backing up with Kopia $(kopia --version)"

echo "Creating Kopia snapshot in local backup repository..."
kopia snapshot create --config-file "$LOCAL_BACKUP_CONFIG" "$SOURCE_PATH"

echo "Syncing local backup repository to remote backup repository..."
kopia repository sync-to from-config --file "$REMOTE_BACKUP_CONFIG" \
    --config-file "$LOCAL_BACKUP_CONFIG" \
    --parallel "$SYNC_PARALLELISM"

echo "Backup complete!"
