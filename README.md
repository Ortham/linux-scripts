Linux scripts
=============

## Backup

I tested out Kopia and Restic, but ended up going with Restic, so the Kopia script is a little older and less fleshed out.

All the scripts except `backup/restic/check-backup-status.sh` need to be run as root as that's needed to create the BTRFS snapshot, and so it makes sense to restrict the config files (which include credentials) to the root user.

The backup scripts need various configuration files to be created. Some are included in this repository, but most contain credentials and so are not included.

Create the services using `sudo systemctl edit --full --force <name>.service` and the timers using `sudo systemctl edit --full --force <name>.timer`, then enable the latter using `sudo systemctl enable <name>.timer`.

For some reason the system services need to call `/bin/sh` explicitly to avoid an exit code of 203, even though the scripts start with a shebang.

### Kopia

The Kopia backup script assumes that `kopia repository create` and `kopia repository connect` have already been run to create the repositories and their config files.

The `home.kopiaignore` file should be installed at `$HOME/.kopiaignore`, while `root.kopiaignore` should be installed at `/.kopiaignore`. Unfortunately if you configure a path to a dot ignore file (as opposed to just a filename), as part of a repository's policy, then snapshots will fail, e.g.:

```
$ kopia --config-file hdd-repository.config policy set / --add-dot-ignore /root/.config/kopia/ignore

$ kopia snapshot create / --config-file hdd-repository.config --log-level debug
...
Snapshotting root@linux-desktop:/ ...
DEBUG uploading {"source":"root@linux-desktop:/","previousManifests":0,"parallel":6}
DEBUG snapshotted directory     {"path":".","error":"unable to parse ignore file ignore: unable to open ignore file: unable to open local file: open //ignore: no such file or directory","dur":"97.659µs"}
...
ERROR upload error: no such file or directory
```

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

#### Status check

The `backup/restic/check-backup-status.sh` script can be installed to `$HOME/.local/bin`, then add the following to `$HOME/.bashrc`:

```
. "$HOME/.local/bin/check-backup-status.sh"
```

The status of the last backup run will then be displayed whenever you open a new terminal.

## Games

The input CSV is most easily created using Playnite's "Library Exporter Advanced" extension, with the Game Id and Sources export options ticked. For Humble Bundle games, I have the Humble library extension configured to "Ignore third party store games" so that Playnite only lists games that are downloadable from Humble Bundle, and not games that I bought on Humble Bundle but that are downloaded through Steam or other clients.

Checking if Linux downloads are available for itch.io games requires an itch.io API key: if one is not provided, the checks will be skipped.

Run the script as:

```
cd games
python -m venv .venv
.venv\Scripts\activate
pip install -r docs/requirements.txt
python .\check-games-compatibility.py [-i <itch.io API key>] <path to exported library CSV> <path to output CSV>
```

That assumes you're running the script on Windows, as although it can run on Linux, Playnite is a Windows application.

## Syncthing

The syncything-conflict-detector service can be installed as a systemd user service.

1. Put `syncthing/notify-syncthing-conflicts.sh` in `$HOME/.local/bin`.
2. Copy the contents of `syncthing/syncthing-conflict-detectors.service` into the editor opened when you run `systemctl --user edit --full --force syncthing-conflict-detector.service`.
3. Run `systemctl --user enable syncthing-conflict-detector` to enable the service.
