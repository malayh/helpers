#!/bin/bash

BACKUP_BUCKET="$1"
TIMESTAMP=$(date +"%Y%m%d_%H%M%S")
FILENAME="/tmp/omarchy_backup_${TIMESTAMP}.tar.gz"

RCLONE_CONFIG_FILE="$HOME/.config/rclone/rclone.conf"

test -f $RCLONE_CONFIG_FILE || {
    echo "Rclone config file not found at $RCLONE_CONFIG_FILE"
    exit 1
}

if [ -z "$BACKUP_BUCKET" ]; then
    echo "Usage: $0 <bucket-name>"
    exit 1
fi


tar -czf ${FILENAME} \
    ~/.local \
    ~/.helpers \
    ~/.vscode \
    ~/.config \
    ~/.aws \
    ~/.ssh \
    ~/.bashrc \
    ~/.bash_profile \
    ~/.kube; 


rclone copy ${FILENAME} "backup-b2:${BACKUP_BUCKET}/omarchy-config/" --progress;
rm ${FILENAME};
rclone delete "backup-b2:${BACKUP_BUCKET}/omarchy-config/" --min-age 3d --include "omarchy_backup_*.tar.gz";

