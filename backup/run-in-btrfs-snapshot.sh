#!/bin/sh
# Runs the given command chrooted into a BTRFS snapshot
set -eE -o pipefail

COMMAND="$1"

if [ -z "$TARGET_PARTITION_UUID" ]
then
        echo "ERROR: TARGET_PARTITION_UUID environment variable is not set!"
        exit 1
fi

cleanup() {
        echo "Tearing down BTRFS snapshot environment..."
        umount "${ROOT_DIR}${TARGET_MOUNT_POINT}" || true
        umount "$ROOT_DIR/run" || true
        umount "$ROOT_DIR/dev" || true
        umount "$ROOT_DIR/proc" || true
        btrfs subvolume delete "$ROOT_DIR/var/home" || true
        btrfs subvolume delete "$ROOT_DIR/var" || true
        btrfs subvolume delete "$ROOT_DIR" || true
        rmdir "$BTRFS_SNAPSHOT_DIR" || true

        echo "Tear down complete!"

        if [ "$UNMOUNT_TARGET_PARTITION" = "true" ]
        then
                echo "Unmounting target partition..."
                udisksctl unmount -b "$TARGET_PARTITION_DEVICE" --no-user-interaction || true

                echo "Target partition successfully unmounted!"
        fi

}

trap 'cleanup' ERR

if [ ! -L "/dev/disk/by-uuid/$TARGET_PARTITION_UUID" ]
then
        echo "ERROR: Target partition is not present! If it's in an external drive, is it plugged in?"
        exit 1
fi

if ! findmnt -S "UUID=$TARGET_PARTITION_UUID"
then
        echo "Mounting target partition..."
        TARGET_PARTITION_DEVICE=$(blkid --uuid "$TARGET_PARTITION_UUID")

        udisksctl mount -b "$TARGET_PARTITION_DEVICE" --no-user-interaction

        UNMOUNT_TARGET_PARTITION=true
fi

TARGET_MOUNT_POINT=$(findmnt -S "UUID=$TARGET_PARTITION_UUID" -f -n -o TARGET)
echo "Using $TARGET_MOUNT_POINT as the target partition's mount point."

# Since Fedora 42 this has become more complicated, as now / is overlaid with
# composefs, and /sysroot holds the original BTRFS subvolume for / as a
# read-only mount, with other subvolumes for /var and /home.
# The /sysroot subvolume snapshot doesn't contain anything interesting: it's
# just empty folders apart from /sysroot/ostree.
# Restic doesn't resolve symlinks, it just backs up the symlink, not what it's
# pointing to.
# /root is a symlink to /var/roothome
# /home is a symlink to /var/home, but is also a subvolume of its own, so the
# snapshot for /var doesn't include it.
# Need to use chroot to run restic on a filesystem that looks like / but
# actually uses the snapshots - if it is given the absolute snapshot paths,
# they'll appear as given in the backup, making tracking changes difficult.
echo "Setting up BTRFS snapshot environment..."

BTRFS_SNAPSHOT_DIR="$(mktemp -d -p /var/tmp -t "btrfs-snapshot.XXXXXXXXXX")"
ROOT_DIR="$BTRFS_SNAPSHOT_DIR/sysroot"

btrfs subvolume snapshot /sysroot "$ROOT_DIR"

# The sysroot snapshot is mostly empty directories.
rmdir "$ROOT_DIR/home"
rmdir "$ROOT_DIR/root"
rmdir "$ROOT_DIR/var"

btrfs subvolume snapshot /var "$ROOT_DIR/var"

# /var/home is empty inside the snapshot, so remove it and create a snapshot
# for home there.
rmdir "$ROOT_DIR/var/home"
btrfs subvolume snapshot /var/home "$ROOT_DIR/var/home"

# Mount directories from / for everything that's not included in subvolumes.
mount -t proc proc "$ROOT_DIR/proc"
mount --bind /dev "$ROOT_DIR/dev"
mount --bind /run "$ROOT_DIR/run"
mount --bind /sys "$ROOT_DIR/sys"

mkdir -p "$TARGET_MOUNT_POINT"
mount --bind "$TARGET_MOUNT_POINT" "${ROOT_DIR}${TARGET_MOUNT_POINT}"

mkdir "$ROOT_DIR/etc"
mount --bind /etc "$ROOT_DIR/etc"

mkdir "$ROOT_DIR/usr"
mount --bind /usr "$ROOT_DIR/usr"

# Set up symlinks to match / for everything that's not included in subvolumes.
ln -s "run/media" "$ROOT_DIR/media"
ln -s "usr/bin" "$ROOT_DIR/bin"
ln -s "usr/lib" "$ROOT_DIR/lib"
ln -s "usr/lib64" "$ROOT_DIR/lib64"
ln -s "usr/sbin" "$ROOT_DIR/sbin"
ln -s "var/home" "$ROOT_DIR/home"
ln -s "var/mnt" "$ROOT_DIR/mnt"
ln -s "var/opt" "$ROOT_DIR/opt"
ln -s "var/roothome" "$ROOT_DIR/root"
ln -s "var/srv" "$ROOT_DIR/srv"

echo "Running $COMMAND chrooted into $ROOT_DIR..."
chroot "$ROOT_DIR" "$COMMAND" "$TARGET_MOUNT_POINT"

cleanup
