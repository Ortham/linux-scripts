#!/bin/sh
# Backup script using Restic.
set -e

LOCAL_REPOSITORY_MOUNT_POINT="$1"
BTRFS_SNAPSHOTS_DIR="$2"
LOCAL_REPOSITORY="${LOCAL_REPOSITORY_MOUNT_POINT}/${LOCAL_REPOSITORY_RELATIVE_PATH}"

if [ -z "$LOCAL_REPOSITORY_MOUNT_POINT" ]
then
        echo "ERROR: Local repository mount point (first argument) is empty!"
        exit 1
fi

echo "Backing up using $(restic version)"

if ! restic -r "$LOCAL_REPOSITORY" -p "$LOCAL_REPOSITORY_PASSWORD_FILE" cat config
then
    echo "Initialising the local backup repository..."
    restic init \
        --repo "$LOCAL_REPOSITORY" \
        --password-file "$LOCAL_REPOSITORY_PASSWORD_FILE"
fi

echo "Creating Restic snapshot in local backup repository..."
restic backup \
    --repo "$LOCAL_REPOSITORY" \
    --password-file "$LOCAL_REPOSITORY_PASSWORD_FILE" \
    --exclude-file "$EXCLUDE_FILE_PATH" \
    --exclude-caches \
    --files-from-verbatim "$FILES_FROM_PATH"

restic check \
    --repo "$LOCAL_REPOSITORY" \
    --password-file "$LOCAL_REPOSITORY_PASSWORD_FILE"

echo "Pruning old snapshots from local repository..."
restic forget \
    --repo "$LOCAL_REPOSITORY"  \
    --password-file "$LOCAL_REPOSITORY_PASSWORD_FILE" \
    --prune \
    --keep-yearly "$KEEP_YEARLY" \
    --keep-monthly "$KEEP_MONTHLY" \
    --keep-weekly "$KEEP_WEEKLY" \
    --keep-daily "$KEEP_DAILY" \
    --keep-hourly "$KEEP_HOURLY" \
    --keep-last "$KEEP_LAST" \
    --keep-within "$KEEP_WITHIN"

restic check \
    --repo "$LOCAL_REPOSITORY" \
    --password-file "$LOCAL_REPOSITORY_PASSWORD_FILE"

if [ -z "$REMOTE_REPOSITORY" ]
then
    echo "No remote repository is configured, skipping syncing the local repository to it."
    echo "Backup complete!"
    exit 0
fi

if ! restic -r "$REMOTE_REPOSITORY" -p "$REMOTE_REPOSITORY_PASSWORD_FILE" cat config
then
    echo "Initialising the remote backup repository..."
    restic init \
        --repo "$REMOTE_REPOSITORY" \
        --password-file "$REMOTE_REPOSITORY_PASSWORD_FILE" \
        --from-repo "$LOCAL_REPOSITORY" \
        --from-password-file "$LOCAL_REPOSITORY_PASSWORD_FILE" \
        --copy-chunker-params
fi

echo "Syncing local backup repoitory to remote backup repository using ${COPY_CONNECTIONS} connections..."
restic copy \
    --repo "$REMOTE_REPOSITORY" \
    --password-file "$REMOTE_REPOSITORY_PASSWORD_FILE" \
    --from-repo "$LOCAL_REPOSITORY" \
    --from-password-file "$LOCAL_REPOSITORY_PASSWORD_FILE" \
    --option s3.connections="$COPY_CONNECTIONS"

restic check \
    --repo "$REMOTE_REPOSITORY" \
    --password-file "$REMOTE_REPOSITORY_PASSWORD_FILE"

echo "Pruning old snapshots from remote repository..."
restic forget \
    --repo "$REMOTE_REPOSITORY" \
    --password-file "$REMOTE_REPOSITORY_PASSWORD_FILE" \
    --prune \
    --keep-yearly "$KEEP_YEARLY" \
    --keep-monthly "$KEEP_MONTHLY" \
    --keep-weekly "$KEEP_WEEKLY" \
    --keep-daily "$KEEP_DAILY" \
    --keep-hourly "$KEEP_HOURLY" \
    --keep-last "$KEEP_LAST" \
    --keep-within "$KEEP_WITHIN"

restic check \
    --repo "$REMOTE_REPOSITORY" \
    --password-file "$REMOTE_REPOSITORY_PASSWORD_FILE"

echo "Backup complete!"
