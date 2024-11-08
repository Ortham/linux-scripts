#!/bin/sh
# Watch for Syncthing sync conflicts and create a desktop notification for each.
# Needs syncthing and inotifywait installed, e.g. dnf install syncthing inotify-tools
set -e -o pipefail

# Adapted from <https://github.com/Martchus/syncthingtray/issues/140#issuecomment-1152718393>
watch_for_conflicts() {
    SYNC_PATHS=("$@")

    echo "Watching for sync conflicts in ${SYNC_PATHS[@]}..."
    inotifywait --monitor --recursive -e create,moved_to --include "sync-conflict" --format '%w%f' ${SYNC_PATHS[@]} |
    while read NEW_FILE
    do
        if [[ "$NEW_FILE" != *tmp ]]
        then
            echo "Sync conflict detected for $NEW_FILE, sending notification..."
            ORIGINAL_PATH=$(echo ${NEW_FILE/#$HOME/\~} | sed -E 's/(.+).sync-conflict-[0-9]{8}-[0-9]{6}-[^\.]+(\..+)/\1\2/')
            notify-send --app-name "Syncthing Conflict Detector" --urgency critical --wait "Syncthing conflict detected!" "Sync conflict detected for $ORIGINAL_PATH" --hint='string:desktop-entry:syncthing-ui'
        fi
    done
}

get_sync_paths() {
    if command -v syncthing 2>&1 >/dev/null
    then
        SYNCTHING_BIN="syncthing cli config folders"
    else
        SYNCTHING_BIN="flatpak run --command=syncthing com.github.zocker_160.SyncThingy cli config folders"
    fi
    $SYNCTHING_BIN list | xargs -I % $SYNCTHING_BIN % path get | sed "s|~|$HOME|"
}

SYNC_PATHS=$(get_sync_paths)

watch_for_conflicts "${SYNC_PATHS[@]}"
