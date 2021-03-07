# istio-csr

cert-manager-istio-csr is an agent which allows for [istio](https://istio.io) workload
and control plane components to be secured using
[cert-manager](https://cert-manager.io). Certificates facilitating mTLS, inter
and intra cluster, will be signed, delivered and renewed using [cert-manager
issuers](https://cert-manager.io/docs/concepts/issuer).


---
<br> 

## Installation
<br> 

Firstly, [cert-manager must be
installed](https://cert-manager.io/docs/installation/) in your cluster. An
issuer must be configured, which will be used to sign your certificate
workloads, as well a ready Certificate to serve istiod. Example Issuer and
istiod Certificate configuration can be found in
[`./hack/demo/cert-manager-bootstrap-resources.yaml`](./hack/demo/cert-manager-bootstrap-resources.yaml).

Next, install the cert-manager-istio-csr into the cluster, configured to use
the Issuer deployed. The Issuer must reside in the same namespace as that
configured by `-c, --certificate-namespace`, which is `istio-system` by default.

<br> 

```bash
$ helm repo add jetstack https://charts.jetstack.io
$ helm repo update

# Cluster 1
$ helm --kube-context="${CTX_CLUSTER1}" install -n cert-manager cert-manager-istio-csr jetstack/cert-manager-istio-csr --set agent.clusterID=cluster1 --set certificate.name=vault-istio-ca1-issuer

# Cluster 2
$ helm --kube-context="${CTX_CLUSTER2}" install -n cert-manager cert-manager-istio-csr jetstack/cert-manager-istio-csr --set agent.clusterID=cluster2 --set certificate.name=vault-istio-ca2-issuer
```

<br> 

Finally, install istio.

```bash
# Cluster1
$ istioctl --context="${CTX_CLUSTER1}" install -f resources/istio-config-cluster1-1.9.1.yaml

# Cluster2 
$ istioctl --context="${CTX_CLUSTER2}" install -f resources/istio-config-cluster1-1.9.1.yaml
```

Istio must be installed using the IstioOperator
configuration changes within
[`resources/istio-config-x.yaml`](resources/istio-config-1.9.1.yaml). These changes are
required in order for the CA Server to be disabled in istiod, ensure istio
workloads request certificates from the cert-manager agent, and the istiod
certificates and keys are mounted in from the Certificate created earlier.
<br> 
<br> 
The istio config file include also the *`multiCluster`* config where we have to set the `meshID`, `clusterName` and the `network`.

```bash

apiVersion: install.istio.io/v1alpha1
kind: IstioOperator
spec:
  values:
    global:
      meshID: mesh1
      multiCluster:
        clusterName: cluster1
      network: network1
```

<br> 

# References

- [Istio CSR](https://github.com/cert-manager/istio-csr)