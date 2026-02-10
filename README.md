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

The `exclude_files` file contains the excludes that are passed to Restic, see [the docs](https://restic.readthedocs.io/en/latest/040_backup.html#excluding-files) for an explanation of the syntax.

The `restic-backup.env` file contains all of the configuration passed to the Restic backup service. There are two settings that have no default value:

- `TARGET_PARTITION_UUID` must be set to the UUID of the partition that holds the local backup repository.

  `ls -l /dev/disk/by-uuid` can help identify which is the correct UUID.
- `REMOTE_REPOSITORY` must be set to the path-based URL of a bucket in S3-compatible storage, e.g. `s3:s3.us-east-1.amazonaws.com/bucket_name`

Two credentials files need to be created:

- `/opt/restic-backup-service/etc/credentials/repository-password` should contain (only) the backup repositories' password.

  If the local and remote repositories should use different passwords, then create two different files in `/opt/restic-backup-service/etc/credentials/` and update `restic-backup.env` to use their paths.
- `/opt/restic-backup-service/etc/credentials/aws-credentials` should look like:

    ```
    [restic]
    aws_access_key_id = <value>
    aws_secret_access_key = <value>
    ```

    where the values are those necessary to access the S3-compatible storage bucket identified by the `REMOTE_REPOSITORY` configuration value.

Install using:

```
cd backup/restic
sudo ./install.sh
```

then create the credentials files. Once they're created, run `sudo systemctl enable restic-backup.timer` to schedule the backups. You can also manually trigger a backup by running `sudo systemctl start restic-backup.service`.

The status of the last backup run will be displayed whenever you open a new terminal.

## Flatpak

The `flatpak/overrides` folder contains files that can be copied to `$HOME/.local/share/flatpak/overrides`. The overrides restrict the permissions of Flatpak apps, removing those that don't seem necessary for the features I use. In general they:

- remove X11-related permissions for apps that have good Wayland support
- remove blanket filesystem access to things like `host`, `home`, etc. and replacing them with more specific items (e.g. `xdg-pictures` for Inkscape)
- remove network access unless that's required for functionality that I use

I haven't extensively tested the apps with these restrictions, so parts of them may not work correctly, and there are some that have optional functionality that I don't use that is broken by these restrictions.

The install script sets up a couple of Flathub remotes, installs the overrides and then installs some applications. It prompts for some applications that I may not want to install.

```
cd flatpak
./install.sh
```

## Games

The input CSV is most easily created using Playnite's "Library Exporter Advanced" extension, with the Game Id and Sources export options ticked. For Humble Bundle games, I have the Humble library extension configured to "Ignore third party store games" so that Playnite only lists games that are downloadable from Humble Bundle, and not games that I bought on Humble Bundle but that are downloaded through Steam or other clients.

Checking if Linux downloads are available for itch.io games requires an itch.io API key: if one is not provided, the checks will be skipped.

Run the script as:

```
cd games
uv run .\check-games-compatibility.py [-i <itch.io API key>] <path to exported library CSV> <path to output CSV>
```

That assumes you're running the script on Windows, as although it can run on Linux, Playnite is a Windows application.

## KDE Window Rules

`pip-always-on-top.kwinrule` is a KDE Window Rule that forces Firefox's Picture-in-Picture windows to always be displayed on top of other windows, as that's not automatically the case when running Firefox on Wayland.

Import the rule file using the Import... option in KDE's System Settings -> Window Management -> Window Rules panel, or use it to recreate the rule in the rule editor GUI.

## Partially fix GNOME Shell Suspend/Resume with Nvidia

Currently if you try to sleep a GNOME desktop that uses an Nvidia graphics card with the proprietary drivers, the system will either not finish going to sleep and become unresponsive, or become unresponsive on waking.

The files in the `nvidia-sleep-gnome` directory were taken from [this forum post](https://forums.developer.nvidia.com/t/trouble-suspending-with-510-39-01-linux-5-16-0-freezing-of-tasks-failed-after-20-009-seconds/200933/12).

Install them using:

```sh
cd gnome/nvidia-sleep
sudo ./install.sh
```

That fixes manually sending a system to sleep and then waking it, but I still get an unresponsive system sometimes when the system automatically sleeps after a period of inactivity.

## Syncthing

The syncything-conflict-detector service can be installed as a systemd user service:

```sh
cd syncthing
./install.sh
```