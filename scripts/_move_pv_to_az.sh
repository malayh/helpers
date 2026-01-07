#!/bin/bash 

PVC_NAME=$1
TARGET_AZ=$2
NEW_PV_SUFFIX=$3
VOLUME_TYPE="gp3" 



if [ -z "$PVC_NAME" ] || [ -z "$TARGET_AZ" ] || [ -z "$NEW_PV_SUFFIX" ]; then
  echo "Usage: _move_pv_to_az.sh <pvc-name> <target-az> <new-pv-suffix>"
  exit 1
fi

JOURNAL_FILE="move_pv_to_az_$(date +%s).log"

echo "Checking tools..."
which kubectl && which aws && which yq >/dev/null
if [ $? -ne 0 ]; then
    echo "Error: kubectl, aws CLI, and yq must be installed and in your PATH"
    exit 1
fi
yq --version | grep mikefarah || {
    echo "Error: yq must be the mikefarah version"
    exit 1
}


echo "Retrieving PV Information..."
PV_NAME=$(kubectl get pvc $PVC_NAME -o jsonpath='{.spec.volumeName}')
PV_VOL_ID=$(kubectl get pv $PV_NAME -o jsonpath='{.spec.csi.volumeHandle}')
PV_AZ=$(kubectl get pv $PV_NAME -o jsonpath='{.spec.nodeAffinity.required.nodeSelectorTerms[0].matchExpressions[?(@.key=="topology.kubernetes.io/zone")].values[0]}')


if [ -z "$PV_NAME" ] || [ -z "$PV_VOL_ID" ] || [ -z "$PV_AZ" ]; then
    echo "Error: Could not retrieve PV information"
    echo "PV_NAME: $PV_NAME"
    echo "PV_VOL_ID: $PV_VOL_ID"
    echo "PV_AZ: $PV_AZ"
    exit 1
fi

echo "PV Name: $PV_NAME"
echo "PV Volume ID: $PV_VOL_ID"
echo "PV Availability Zone: $PV_AZ"
echo "Target Availability Zone: $TARGET_AZ"

read -p "Are you sure you want to move PV '$PV_NAME' from AZ '$PV_AZ' to AZ '$TARGET_AZ'? (y/n): " CONFIRM
if [[ "$CONFIRM" != "y" ]]; then
    echo "Operation cancelled."
    exit 0
fi

echo "Updating current PV to use 'Retain' reclaim policy..."
kubectl patch pv $PV_NAME -p '{"spec":{"persistentVolumeReclaimPolicy":"Retain"}}'
if [ $? -ne 0 ]; then
    echo "Error: Failed to update PV reclaim policy"
    exit 1
fi



echo "Creating snapshot of the volume..."
SNAPSHOT_ID=$(aws ec2 create-snapshot --volume-id $PV_VOL_ID --description "Snapshot of $PV_VOL_ID for moving to $TARGET_AZ" --query 'SnapshotId' --output text)
if [ -z "$SNAPSHOT_ID" ]; then
    echo "Error: Failed to create snapshot"
    exit 1
fi
echo "Snapshot created with ID: $SNAPSHOT_ID"
echo "Snapshot ID: $SNAPSHOT_ID" >> $JOURNAL_FILE

echo "Waiting for snapshot to complete..."
aws ec2 wait snapshot-completed --snapshot-ids $SNAPSHOT_ID



echo "Creating new volume in target AZ '$TARGET_AZ'..."
NEW_VOL_ID=$(aws ec2 create-volume --snapshot-id $SNAPSHOT_ID --availability-zone $TARGET_AZ --volume-type $VOLUME_TYPE --query 'VolumeId' --output text)
if [ -z "$NEW_VOL_ID" ]; then
    echo "Error: Failed to create new volume"
    exit 1
fi
echo "New volume created with ID: $NEW_VOL_ID"
echo "New Volume ID: $NEW_VOL_ID" >> $JOURNAL_FILE

echo "Waiting for new volume to become available..."
aws ec2 wait volume-available --volume-ids $NEW_VOL_ID
echo "New volume is now available."



echo "Creating new PV manifest..."
NEW_PV_NAME="${PV_NAME}-${NEW_PV_SUFFIX}"
kubectl get pv $PV_NAME -o yaml > new-pv.yaml
yq -i ".metadata.name = \"$NEW_PV_NAME\"" new-pv.yaml
yq -i ".spec.csi.volumeHandle = \"$NEW_VOL_ID\"" new-pv.yaml
yq -i ".spec.nodeAffinity.required.nodeSelectorTerms[0].matchExpressions[0].values[0] = \"$TARGET_AZ\"" new-pv.yaml
yq -i "del(.spec.claimRef)" new-pv.yaml
yq -i "del(.metadata.uid)" new-pv.yaml
yq -i "del(.status)" new-pv.yaml

read -p "Review the new PV manifest in 'new-pv.yaml'. Press enter to continue..."

echo "Applying new PV manifest..."
kubectl apply -f new-pv.yaml

if [ $? -ne 0 ]; then
    echo "Error: Failed to create new PV"
    exit 1
fi

echo "Operation completed successfully. New PV '$NEW_PV_NAME' created in AZ '$TARGET_AZ'."
echo "New PV Name: $NEW_PV_NAME" >> $JOURNAL_FILE

read -p "Press enter to clean up snapshot '$SNAPSHOT_ID'..."
echo "Deleting snapshot '$SNAPSHOT_ID'..."
aws ec2 delete-snapshot --snapshot-id $SNAPSHOT_ID
echo "Snapshot deleted."

echo "Cleanup completed. Journal saved to '$JOURNAL_FILE'. You can delete previous PV '$PV_NAME' manually if no longer needed."
