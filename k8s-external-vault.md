> Before proceeding, be sure to complete the follwing steps:

## Environment Variables

This guide will refer to two clusters: `cluster1` and `cluster2`. The following environment variables will be used throughout to simplify the instructions:

<br>

| Variable      | Description |
| ----------- | ----------- |
| CTX_CLUSTER1   | The context name in the default Kubernetes configuration file used for accessing the cluster1.       |
| CTX_CLUSTER2   | The context name in the default Kubernetes configuration file used for accessing the cluster2.       |

<br>

Set the two variables before proceeding:

```bash
$ kubectl config get-contexts

CURRENT   NAME                                                        CLUSTER                                                     AUTHINFO                                                    NAMESPACE
          gke_marius-playground_europe-west1-b_istio-demo-cluster-2   gke_marius-playground_europe-west1-b_istio-demo-cluster-2   gke_marius-playground_europe-west1-b_istio-demo-cluster-2   
*         gke_marius-playground_us-central1-c_istio-demo-cluster-1    gke_marius-playground_us-central1-c_istio-demo-cluster-1    gke_marius-playground_us-central1-c_istio-demo-cluster-1    


$ export CTX_CLUSTER1=<your cluster1 context name>
$ export CTX_CLUSTER2=<your cluster2 context name>
````

<br>

# Define a Kubernetes service account

Create a service account, secret, and ClusterRoleBinding with the necessary permissions to allow Vault to perform token reviews with Kubernetes.

```bash
$ cat <<EOF | kubectl --context="${CTX_CLUSTER1}" create -f -
---
apiVersion: v1
kind: ServiceAccount
metadata:
  name: vault-auth
---
apiVersion: v1
kind: Secret
metadata:
  name: vault-auth
  annotations:
    kubernetes.io/service-account.name: vault-auth
type: kubernetes.io/service-account-token
---
apiVersion: rbac.authorization.k8s.io/v1beta1
kind: ClusterRoleBinding
metadata:
  name: role-tokenreview-binding
roleRef:
  apiGroup: rbac.authorization.k8s.io
  kind: ClusterRole
  name: system:auth-delegator
subjects:
  - kind: ServiceAccount
    name: vault-auth
    namespace: default
EOF
````
> run the same also in `cluster2` by changing the context to: `--context="${CTX_CLUSTER2}"` <br>

This creates the vault-auth service account, the vault-auth secret, and the ClusterRoleBinding that uses the created service account.

<br>

# Configure Kubernetes authentication

Vault provides a Kubernetes authentication method that enables clients to authenticate with a Kubernetes Service Account Token.

<br>
Enable the Kubernetes authentication method.


```bash

$ vault auth enable --path="kube-demo-cluster-1" kubernetes
Success! Enabled kubernetes auth method at: kube-demo-cluster-1/

$ vault auth enable --path="kube-demo-cluster-2" kubernetes
Success! Enabled kubernetes auth method at: kube-demo-cluster-2/

````
_____________

<br>
   
Vault accepts this service token from any client within the Kubernetes cluster. During authentication, Vault verifies that the service account token is valid by querying a configured Kubernetes endpoint. To configure it correctly requires capturing the JSON web token (JWT) for the service account, the Kubernetes CA certificate, and the Kubernetes host URL.

<br>

First, get the JSON web token (JWT) for this service account.
<br>


```bash

$ TOKEN_REVIEW_JWT1=$(kubectl --context="${CTX_CLUSTER1}" get secret vault-auth -o go-template='{{ .data.token }}' | base64 --decode)

$ TOKEN_REVIEW_JWT2=$(kubectl --context="${CTX_CLUSTER2}" get secret vault-auth -o go-template='{{ .data.token }}' | base64 --decode)

````

Next, retrieve the Kubernetes CA certificate.

```bash

$ KUBE_CA_CERT1=$(kubectl --context="${CTX_CLUSTER1}" config view --raw --minify --flatten -o jsonpath='{.clusters[].cluster.certificate-authority-data}' | base64 --decode)


$ KUBE_CA_CERT2=$(kubectl --context="${CTX_CLUSTER2}" config view --raw --minify --flatten -o jsonpath='{.clusters[].cluster.certificate-authority-data}' | base64 --decode)

````

Next, retrieve the Kubernetes host URL.

```bash

$ KUBE_HOST1=$(kubectl --context="${CTX_CLUSTER1}" config view --raw --minify --flatten -o jsonpath='{.clusters[].cluster.server}')

$ KUBE_HOST2=$(kubectl --context="${CTX_CLUSTER2}" config view --raw --minify --flatten -o jsonpath='{.clusters[].cluster.server}')

```

Finally, configure the Kubernetes authentication method to use the service account token, the location of the Kubernetes host, and its certificate.

```bash

$ vault write auth/kube-demo-cluster-1/config \
        token_reviewer_jwt="$TOKEN_REVIEW_JWT1" \
        kubernetes_host="$KUBE_HOST1" \
        kubernetes_ca_cert="$KUBE_CA_CERT1"
                

$ vault write auth/kube-demo-cluster-2/config \
        token_reviewer_jwt="$TOKEN_REVIEW_JWT2" \
        kubernetes_host="$KUBE_HOST2" \
        kubernetes_ca_cert="$KUBE_CA_CERT2"

```  
<br>  
Last thing is to create a Kubernetes authentication role named issuer-istio-ca.


```bash

$ vault write auth/kube-demo-cluster-1/role/issuer-istio-ca1 \
    bound_service_account_names=vault-issuer \
    bound_service_account_namespaces=istio-system \
    policies=pki-istio-ca \
    ttl=20m
    
 
$ vault write auth/kube-demo-cluster-2/role/issuer-istio-ca2 \
    bound_service_account_names=vault-issuer \
    bound_service_account_namespaces=istio-system \
    policies=pki-istio-ca \
    ttl=20m   

````

The role connects the Kubernetes service account, vault-issuer, and namespace, istio-system, with the Vault policy, pki-istio-ca. The tokens returned after authentication are valid for 20 minutes.

<br>  

# References

- Integrate a Kubernetes Cluster with an External Vault[1] (https://learn.hashicorp.com/tutorials/vault/kubernetes-external-vault)
- Kubernetes Auth Method [2] (https://www.vaultproject.io/docs/auth/kubernetes)