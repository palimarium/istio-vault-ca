# Deploy Cert Manager

Jetstack's cert-manager is a Kubernetes add-on that automates the management and issuance of TLS certificates from various issuing sources. Vault can be configured as one of those sources. 


Create a namespace named `cert-manager` to host the cert-manager.

```bash
$ kubectl --context="${CTX_CLUSTER1}" create namespace cert-manager
namespace/cert-manager created

$ kubectl --context="${CTX_CLUSTER2}" create namespace cert-manager
namespace/cert-manager created
```

Jetstack's cert-manager Helm chart is available in a repository that they maintain. Helm can request and install Helm charts from these custom repositories.

Add the `jetstack` chart repository.

```bash
$ helm repo add jetstack https://charts.jetstack.io
"jetstack" has been added to your repositories
```

Helm maintains a cached list of charts for every repository that it maintains. This list needs to be updated periodically so that Helm knows about all available charts and their releases. A repository recently added needs to be updated before any chart is requested.

Update the local list of Helm charts.


```bash
$ helm repo update
Hang tight while we grab the latest from your chart repositories...
...Successfully got an update from the "jetstack" chart repository
Update Complete. ⎈ Happy Helming!⎈
```

The results show that the `jetstack` chart repository has retrieved an update.

Install the cert-manager chart version 1.2.0 in the `cert-manager` namespace.

```bash
helm --kube-context="${CTX_CLUSTER1}" install \
  cert-manager jetstack/cert-manager \
  --namespace cert-manager \
  --version v1.2.0 \
  --set installCRDs=true


helm --kube-context="${CTX_CLUSTER2}" install \
  cert-manager jetstack/cert-manager \
  --namespace cert-manager \
  --version v1.2.0 \
  --set installCRDs=true
```  

The cert-manager chart deploys a number of pods within the `cert-manager` namespace.

Get all the pods within the `cert-manager` namespace.

```bash
$ kubectl get pods --namespace cert-manager
NAME                                       READY   STATUS    RESTARTS   AGE
cert-manager-756bb56c5-mstl8               1/1     Running   0          21s
cert-manager-cainjector-86bc6dc648-92ghs   1/1     Running   0          21s
cert-manager-webhook-66b555bb5-fpcvq       1/1     Running   0          21s
```

Wait until the pods prefixed with `cert-manager` are running and ready (`1/1`).

Thes pods now require configuration to interface with Vault.

<br>  

# Setting up Vault Issuers

The cert-manager enables you to define Issuers that interface with the Vault certificate generating endpoints. These Issuers are invoked when a Certificate is created.

When you configured Vault's Kubernetes authentication a Kubernetes service account, named `issuer`, was granted the policy, named `pki`, to the certificate generation endpoints.

Create a namespace named `istio-system` to host the istio installation.

```bash
$ kubectl --context="${CTX_CLUSTER1}" create namespace istio-system
namespace/istio-system created

$ kubectl --context="${CTX_CLUSTER2}" create namespace istio-system
namespace/istio-system created
```

Create a service account named `vault-issuer` within the istio-system namespace.

```bash
$  kubectl --context="${CTX_CLUSTER1}" create serviceaccount vault-issuer -n istio-system
serviceaccount/vault-issuer created

$  kubectl --context="${CTX_CLUSTER2}" create serviceaccount vault-issuer -n istio-system
serviceaccount/vault-issuer created

```

The service account generated a secret that is required by the Issuer.

Get all the secrets in the default namespace.

```bash
$ kubectl get secrets
default-token-mlm2n           kubernetes.io/service-account-token   3      13d
issuer-token-lmzpj            kubernetes.io/service-account-token   3      47s
sh.helm.release.v1.vault.v1   helm.sh/release.v1                    1      28m
vault-token-749nd             kubernetes.io/service-account-token   3      28m
```

The issuer secret is displayed here as the secret prefixed with `issuer-token`.

Create a variable named `ISSUER_SECRET_REF` to capture the secret name.

```bash
ISSUER_SECRET_REF=$(kubectl --context="${CTX_CLUSTER1}" get serviceaccount vault-issuer -n istio-system -o json | jq -r ".secrets[].name")

ISSUER_SECRET_REF=$(kubectl --context="${CTX_CLUSTER2}" get serviceaccount vault-issuer -n istio-system -o json | jq -r ".secrets[].name")
```

Create an Issuer, named `vault-istio-ca-issuer`, that defines Vault as a certificate issuer.

> Cluster 1

```bash
cat <<EOF | kubectl --context="${CTX_CLUSTER1}" apply -f -
apiVersion: cert-manager.io/v1
kind: Issuer
metadata:
  name: vault-istio-ca1-issuer
  namespace: istio-system
spec:
  vault:
    server: https://vault-server-XXXXXX-uw.a.run.app
    path: pki_int1/sign/istio-ca1
    auth:
      kubernetes:
        mountPath: /v1/auth/kube-demo-cluster-1
        role: issuer-istio-ca1
        secretRef:
          name: $ISSUER_SECRET_REF
          key: token
EOF 
```

> Cluster 2

```bash
cat <<EOF | kubectl --context="${CTX_CLUSTER2}" apply -f -
apiVersion: cert-manager.io/v1
kind: Issuer
metadata:
  name: vault-istio-ca2-issuer
  namespace: istio-system
spec:
  vault:
    server: https://vault-server-XXXXXX-uw.a.run.app
    path: pki_int2/sign/istio-ca2
    auth:
      kubernetes:
        mountPath: /v1/auth/kube-demo-cluster-2
        role: issuer-istio-ca2
        secretRef:
          name: $ISSUER_SECRET_REF
          key: token
EOF
```

The specification defines the signing endpoint and the authentication endpoint and credentials.

* `metadata.name` sets the name of the Issuer to vault-istio-ca-issuer
* `spec.vault.server` sets the server address to the Kubernetes service created in the istio-system namespace
* `spec.vault.path` is the signing endpoint created by Vault's PKI `istio-ca` role
* `spec.vault.auth.kubernetes.mountPath` sets the Vault authentication endpoint
* `spec.vault.auth.kubernetes.role` sets the Vault Kubernetes role to `issuer`
* `spec.vault.auth.kubernetes/secretRef.name` sets the secret for the Kubernetes service account
* `spec.vault.auth.kubernetes/secretRef.key` sets the type to `token`.

<br> 
<br> 

# References

- [Deploy Cert Manager](https://learn.hashicorp.com/tutorials/vault/kubernetes-cert-manager#deploy-cert-manager)
- [Cert manager Vault](https://cert-manager.io/docs/configuration/vault/)