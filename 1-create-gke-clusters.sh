#!/usr/bin/env bash

set -euo pipefail
source ./env.sh


# Create Private GKE Cluster 1 in europe-west2

gcloud beta container clusters create $NAME_CLUSTER1 --project $PROJECT_ID --zone $ZONE_CLUSTER1 \
--machine-type "n1-standard-2" --image-type "COS" --disk-size "100"  \
--enable-ip-alias --network "projects/$PROJECT_ID/global/networks/default" \
--subnetwork "projects/$PROJECT_ID/regions/$REGION_CLUSTER1/subnetworks/default"  \
--default-max-pods-per-node "110" --num-nodes "3" --release-channel "regular" &

# Create Private GKE Cluster 2 in us-central1

gcloud beta container clusters create $NAME_CLUSTER2 --project $PROJECT_ID --zone $ZONE_CLUSTER2 \
--machine-type "n1-standard-2" --image-type "COS" --disk-size "100"  \
--enable-ip-alias --network "projects/$PROJECT_ID/global/networks/default" \
--subnetwork "projects/$PROJECT_ID/regions/$REGION_CLUSTER2/subnetworks/default"  \
--default-max-pods-per-node "110" --num-nodes "3" --release-channel "regular" &

# wait for clusters to be created
wait < <(jobs -p)
