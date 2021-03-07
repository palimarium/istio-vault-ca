# Multicluster Istio1.9 and Hashicorp Vault CA Integration

## Introduction

This tutorial shows you a full end-to-end example on how to integrate a Vault Certificate Authority (CA) with a multicluster Istio, to issue certificates for workloads in the mesh.



## Implementation Architecture

In this tutorial, we will build the following architecture:

![arch-diagram](resources/images/medium1.png)

## Prerequisites


- A GCP project with billing enabled
- gcloud CLI
- kubectl

<br/>

## Set project variables

``` bash
❯ export PROJECT_ID=<your-project-id>
```

<br/>


# Setup

## 1) [Create Hashicorp Vault Cluster](https://github.com/kelseyhightower/serverless-vault-with-cloud-run#tutorial)


## 2) Create GKE Clusters


```bash
my@localhost:~$./1-create-gke-clusters.sh
```


## 3) [Connect GKE clusters with External Vault](k8s-external-vault.md)

## 4) [Configure Vault PKI secrets engine](https://gist.github.com/palimarium/3a0c7a1026f0789f7ce1d7f2689665f9)

## 5) [Deploy Cert Manager](cert-manager-setup.md) 

## 6) [Install Cert Manager istio-csr](istio-csr-setup.md)

## 7) [Multicluster Istio installation](https://istio.io/latest/docs/setup/install/multicluster/multi-primary_multi-network/)

## 8) [Deploy the HelloWorld application](https://istio.io/latest/docs/setup/install/multicluster/verify/)