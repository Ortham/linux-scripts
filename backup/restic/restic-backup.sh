#!/bin/sh  
# Backup script using Restic.  
set -e  
  
SOURCE_PATHS=(/etc /home /root)
LOCAL_REPOSITORY_MOUNT_POINT="$1"
LOCAL_REPOSITORY="${LOCAL_REPOSITORY_MOUNT_POINT}/Backups/Restic"  
REMOTE_REPOSITORY_FILE="/root/.config/restic/remote-repository"  
EXCLUDE_FILE_PATH="/root/.config/restic/exclude"  
COPY_CONNECTIONS=5
export RESTIC_PASSWORD_FILE="/root/.config/restic/repository-password"  
export AWS_PROFILE=restic
export AWS_SHARED_CREDENTIALS_FILE=/root/.config/restic/aws-credentials
export PATH="/root/.local/bin:$PATH"
export RESTIC_CACHE_DIR="/root/.cache/restic"

echo "Backing up using $(restic version)"
  
echo "Creating Restic snapshot in local backup repository..."  
restic -r "$LOCAL_REPOSITORY" backup "${SOURCE_PATHS[@]}" --exclude-file "$EXCLUDE_FILE_PATH" --exclude-caches  
restic -r "$LOCAL_REPOSITORY" check  
  
echo "Pruning old snapshots from local repository..."  
restic -r "$LOCAL_REPOSITORY" forget --prune --keep-yearly 3 --keep-monthly 24 --keep-weekly 4 --keep-daily 7 --keep-hourly 48 --keep-last 10  
  
echo "Syncing local backup repoitory to remote backup repository using ${COPY_CONNECTIONS} connections..."
restic --repository-file "$REMOTE_REPOSITORY_FILE" copy --from-repo "$LOCAL_REPOSITORY" --from-password-file "$RESTIC_PASSWORD_FILE" -o s3.connections="$COPY_CONNECTIONS"
restic --repository-file "$REMOTE_REPOSITORY_FILE" check  
  
echo "Pruning old snapshots from remote repository..."  
restic --repository-file "$REMOTE_REPOSITORY_FILE" forget --prune --keep-yearly 3 --keep-monthly 24 --keep-weekly 4 --keep-daily 7 --keep-hourly 48 --keep-last 10  
  
echo "Backup complete!"