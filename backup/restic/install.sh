#!/bin/sh
set -e -o pipefail

rename_existing_file() {
    TARGET_PATH="$1"

    if [ -f "$TARGET_PATH" ]
    then
        TIMESTAMP_SUFFIX=$(date '+%+4Y%m%dT%H%M%S')
        FILENAME=$(basename "$TARGET_PATH")
        echo "Renaming existing $FILENAME file to $TARGET_PATH.$TIMESTAMP_SUFFIX.bak"
        mv "$TARGET_PATH" "$TARGET_PATH.$TIMESTAMP_SUFFIX.bak"
    fi
}

BIN_DIR=/opt/restic-backup-service/bin
CONFIG_DIR=/opt/restic-backup-service/etc


mkdir -p "$BIN_DIR"
mkdir -p "$CONFIG_DIR/credentials"

# Restrict permissions in configuration directory.
chmod go-w "$CONFIG_DIR"
chmod go-rwx "$CONFIG_DIR/credentials"

# These scripts rely on jq being installed.
cp -f check-backup-status.sh "$BIN_DIR"
cp -f run-restic-backup.sh "$BIN_DIR"
cp -f ../run-in-btrfs-snapshot.sh "$BIN_DIR"

rename_existing_file "$CONFIG_DIR/exclude_files"
cp exclude_files "$CONFIG_DIR"

rename_existing_file "$CONFIG_DIR/include_files"
cp include_files "$CONFIG_DIR"

rename_existing_file "$CONFIG_DIR/restic-backup.env"
sed "s/CONFIG_DIR/${CONFIG_DIR//\//\\/}/g" restic-backup.env > "$CONFIG_DIR/restic-backup.env"

sed -e "s/BIN_DIR/${BIN_DIR//\//\\/}/g" \
    -e "s/CONFIG_DIR/${CONFIG_DIR//\//\\/}/g" \
    restic-backup.service > /etc/systemd/system/restic-backup.service

cp -f restic-backup.timer /etc/systemd/system/

systemctl daemon-reload

# Could just update /etc/bashrc instead, but this means the checks can be
# disabled by and for individual users without using sudo.
for USER_HOME in /home/*
do
    BASHRC_DIR="$USER_HOME/.bashrc.d"
    if [ ! -e "$BASHRC_DIR" ]
    then
        mkdir "$BASHRC_DIR"
        chown --reference "$USER_HOME" "$BASHRC_DIR"
    fi

    if [ -d "$BASHRC_DIR" ]
    then
        SCRIPT_TO_RUN="$BIN_DIR/check-backup-status.sh"
        USER_SCRIPT_PATH="$BASHRC_DIR/check-restic-backup-status.sh"

        cat > "$USER_SCRIPT_PATH" << EOF
if [ -f "$SCRIPT_TO_RUN" ]
then
    . "$SCRIPT_TO_RUN"
fi
EOF
        chown --reference "$USER_HOME" "$USER_SCRIPT_PATH"

        echo "Registered the backup check in $USER_SCRIPT_PATH"
    fi
done

echo "The restic backup service has been installed."
