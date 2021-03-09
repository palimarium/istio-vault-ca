#!/usr/bin/env bash

PROJECT_ID="${PROJECT_ID:?PROJECT_ID env variable must be specified ex. export PROJECT_ID=<your-gcp-project_ID>}"

###Cluster 1
NAME_CLUSTER1="demo-istio-cluster1"
ZONE_CLUSTER1="europe-west2-a"
REGION_CLUSTER1="$(echo $ZONE_CLUSTER1 | grep -o '^[^-]*-\?[^-]*' )"
CTX_CLUSTER1="gke_${PROJECT_ID}_${ZONE_CLUSTER1}_${NAME_CLUSTER1}"

###Cluster 2
NAME_CLUSTER2="demo-istio-cluster2"
ZONE_CLUSTER2="us-central1-a"
REGION_CLUSTER2="$(echo $ZONE_CLUSTER2 | grep -o '^[^-]*-\?[^-]*' )"
CTX_CLUSTER2="gke_${PROJECT_ID}_${ZONE_CLUSTER2}_${NAME_CLUSTER2}"

