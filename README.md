Linux scripts
=============

## Backup

I tested out Kopia and Restic, but ended up going with Restic, so the Kopia script is a little older and less fleshed out.

All the scripts except `backup/restic/check-backup-status.sh` need to be run as root as that's needed to create the BTRFS snapshot, and so it makes sense to restrict the config files (which include credentials) to the root user.

The backup scripts need various configuration files to be created. Some are included in this repository, but most contain credentials and so are not included.

Create the services using `sudo systemctl edit --full --force <name>.service` and the timers using `sudo systemctl edit --full --force <name>.timer`, then enable the latter using `sudo systemctl enable <name>.timer`.

### Restic

The Restic backup script assumes that the same password is used for the local and remote repositories, that the local repository was created using:

```
restic -r "$MOUNT_POINT/Backups/Restic" init
```

and that the remote repository was created in S3-compatible storage using:

```
export AWS_PROFILE=restic
export AWS_SHARED_CREDENTIALS_FILE=/root/.config/restic/aws-credentials
restic -r s3:$BUCKET_LOCATION init --from-repo $MOUNT_POINT/Backups/Restic/ --copy-chunker-params  
```

where `$MOUNT_POINT` is the mount point of a drive that holds the local backup, `$BUCKET_LOCATION` is the bucket that holds the remote repository, and the file at `$AWS_SHARED_CREDENTIALS_FILE` already exists and contains a `restic` profile with valid credentials.

`EXTERNAL_DRIVE_UUID` in `backup/run-in-btrfs-snapshot.sh` needs to be the UUID of the partition that holds the local backup repository.

If the backup repository's path within that partition is not `Backups/Restic` then `LOCAL_REPOSITORY` in `restic-backup.sh` will need to be updated to reflect that.

If the source directories are not `/etc`, `/home` and `/root`, then `SOURCE_PATHS` in `backup/restic/restic-backup.sh` will need to be updated.

## Syncthing

The syncything-conflict-detector service can be installed as a systemd user service.

1. Put `syncthing/notify-syncthing-conflicts.sh` in `$HOME/.local/bin`.
2. Copy the contents of `syncthing/syncthing-conflict-detectors.service` into the editor opened when you run `systemctl --user edit --full --force syncthing-conflict-detector.service`.
3. Run `systemctl --user enable syncthing-conflict-detector` to enable the service.