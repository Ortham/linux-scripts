#!/bin/sh
# Runs the given command chrooted into a BTRFS snapshot
set -eE -o pipefail

COMMAND="$1"
EXTERNAL_DRIVE_UUID="D8186958186936A2"

cleanup() {
        echo "Tearing down BTRFS snapshot environment..."
        umount "${ROOT_DIR}${EXTERNAL_DRIVE_MOUNT_POINT}" || true
        umount "$ROOT_DIR/run" || true
        umount "$ROOT_DIR/dev" || true
        umount "$ROOT_DIR/proc" || true

        btrfs subvolume delete "$ROOT_DIR/home" || true
        btrfs subvolume delete "$ROOT_DIR" || true
        rmdir "$BTRFS_SNAPSHOT_DIR" || true

        echo "Tear down complete!"

        if [ "$UNMOUNT_EXTERNAL_DRIVE" = "true" ]
        then
                echo "Unmounting external drive..."
                udisksctl unmount -b "$EXTERNAL_DRIVE_DEVICE" --no-user-interaction || true

                echo "External drive successfully unmounted!"
        fi

}

trap 'cleanup' ERR

if [ ! -L "/dev/disk/by-uuid/$EXTERNAL_DRIVE_UUID" ]
then
        echo "ERROR: External drive is not plugged in!"
        exit 1
fi

if [[ ! $(findmnt -S "UUID=$EXTERNAL_DRIVE_UUID") ]]
then
        echo "Mounting external drive..."
        EXTERNAL_DRIVE_DEVICE=$(blkid --uuid "$EXTERNAL_DRIVE_UUID")

        udisksctl mount -b "$EXTERNAL_DRIVE_DEVICE" --no-user-interaction

        UNMOUNT_EXTERNAL_DRIVE=true
fi

EXTERNAL_DRIVE_MOUNT_POINT=$(findmnt -S "UUID=$EXTERNAL_DRIVE_UUID" -f -n -o TARGET)
echo "Using $EXTERNAL_DRIVE_MOUNT_POINT as the local backup drive's mount point."

BTRFS_SNAPSHOT_DIR="$(mktemp -d -p /var/tmp -t "btrfs-snapshot.XXXXXXXXXX")"
ROOT_DIR="$BTRFS_SNAPSHOT_DIR/root"

echo "Setting up BTRFS snapshot environment..."
btrfs subvolume snapshot / "$ROOT_DIR"
rmdir "$ROOT_DIR/home"

btrfs subvolume snapshot /home "$ROOT_DIR/home"

mount -t proc proc "$ROOT_DIR/proc"
mount --bind /dev "$ROOT_DIR/dev"
mount --bind /run "$ROOT_DIR/run"
mount --bind "$EXTERNAL_DRIVE_MOUNT_POINT" "${ROOT_DIR}${EXTERNAL_DRIVE_MOUNT_POINT}"

echo "Running $COMMAND chrooted into $ROOT_DIR..."
chroot "$ROOT_DIR" "$COMMAND" "$EXTERNAL_DRIVE_MOUNT_POINT"

cleanup