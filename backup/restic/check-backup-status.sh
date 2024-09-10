#!/bin/sh
# Check when the Restic backup service last ran and whether it succeeded or failed.
print_backup_status() {
    SERVICE_NAME=restic-backup.service
    if [[ $(systemctl list-unit-files "$SERVICE_NAME" | wc -l) -eq 3 ]]
    then
        return;
    fi

    JSON="$(journalctl -u restic-backup -g 'restic-backup.service' -o json -r | jq -c '. | select(.JOB_RESULT != null) | {SUCCESS: (.JOB_RESULT | test("done")),  TIMESTAMP: ((.__REALTIME_TIMESTAMP | tonumber) / 1000000 | floor)}' | head -n 1)"

    BACKUP_STATUS_CODE="$(echo "$JSON" | jq -c 'if .SUCCESS then 0 else 1 end')"

    if [[ "$BACKUP_STATUS_CODE" -eq 0 ]]
    then
        BACKUP_STATUS="\e[32msucceeded\e[0m."
    else
        BACKUP_STATUS="\e[31mfailed\e[0m!"
    fi

    BACKUP_TIMESTAMP=$(systemctl show "$SERVICE_NAME" --property ExecMainExitTimestamp | cut -d = -f 2)

    BACKUP_TIMESTAMP="$(echo "$JSON" | jq -c '.TIMESTAMP' | xargs -I '{}' date -d @{})"

    echo -e "The Restic backup last ran at $BACKUP_TIMESTAMP and $BACKUP_STATUS\n"
}

print_backup_status
