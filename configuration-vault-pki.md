```bash

# Creating the root CA:
# First, enable the pki secrets engine at the pki path:

$ vault secrets enable pki

# Tune the pki secrets engine to issue certificates with a maximum time-to-live (TTL) 
#   of 87600 hours (10 years):

$ vault secrets tune -max-lease-ttl=87600h pki

# Generate the root CA, extracting the root CA's certificate to CA_cert.crt; the secret
#   key is not exported!

$ vault write -field=certificate pki/root/generate/internal \
  common_name="istio-ca" ttl=87600h > CA_cert.crt


# This generates a new self-signed CA certificate and private key. Vault will automatically
#   revoke the generated root at the end of its lease period (TTL); the CA certificate will sign its own Certificate Revocation List (CRL).

# Configure the CA and CRL URLs:

 $  vault write pki/config/urls \
    issuing_certificates="https://vault-server-o2wqd4h6la-uw.a.run.app/v1/pki/ca" \
    crl_distribution_points="https://vault-server-o2wqd4h6la-uw.a.run.app/v1/pki/crl"

# Creating the intermediate CA's:
# First, enable the pki secrets engine at the pki_int1/pki_int2 path:

# Cluster1
$ vault secrets enable -path=pki_int1 pki

# Cluster2
$ vault secrets enable -path=pki_int2 pki


# Tune the pki_int secrets engine to issue certificates with a maximum time-to-live (TTL)
#   of 43800 hours (5 years):

$ vault secrets tune -max-lease-ttl=43800h pki_int1

$ vault secrets tune -max-lease-ttl=43800h pki_int2


$ vault secrets list
Path          Type         Accessor              Description
----          ----         --------              -----------
cubbyhole/    cubbyhole    cubbyhole_7c412e02    per-token private secret storage
identity/     identity     identity_67658f5b     identity store
pki/          pki          pki_2186b992          n/a
pki_int1/     pki          pki_e2f26ce3          n/a
pki_int2/     pki          pki_9e1f1ff2          n/a
sys/          system       system_2682ba87       system endpoints used for control, policy and debugging

# Execute the following commands to generate the intermediate CA's and save the CSR as 
#   pki_intermediate1.csr:

$ vault write -format=json pki_int1/intermediate/generate/internal \
        common_name="Istio-ca Intermediate Authority1" \
        | jq -r '.data.csr' > pki_intermediate1.csr

$ vault write -format=json pki_int2/intermediate/generate/internal \
        common_name="Istio-ca Intermediate Authority2" \
        | jq -r '.data.csr' > pki_intermediate2.csr        


# The above command has left a Certificate Signing Request output into your current directory - pki_intermediate.csr


# Sign the intermediate certificate with the root certificate and save the generated
#   certificate as intermediate.cert.pem:


$ vault write -format=json pki/root/sign-intermediate csr=@pki_intermediate1.csr \
        format=pem ttl="43800h" \
        | jq -r '.data.certificate' > intermediate1.cert.pem


$ vault write -format=json pki/root/sign-intermediate csr=@pki_intermediate2.csr \
        format=pem ttl="43800h" \
        | jq -r '.data.certificate' > intermediate2.cert.pem


# append the RootCA to the pem to create a chain

cat intermediate1.cert.pem > intermediate1.chain.pem
cat CA_cert.crt >> intermediate1.chain.pem  

cat intermediate2.cert.pem > intermediate2.chain.pem
cat CA_cert.crt >> intermediate2.chain.pem 

# Once the CSR is signed and the root CA returns a certificate, it can be imported back 
#   into Vault:


$ vault write pki_int1/intermediate/set-signed certificate=@intermediate1.chain.pem

$ vault write pki_int2/intermediate/set-signed certificate=@intermediate2.chain.pem


# Configure a role named istio-ca that enables the creation of certificates istio-ca domain with any name.


# Cluster1
$ vault write pki_int1/roles/istio-ca1 \
    allowed_domains=istio-ca \
    allow_any_name=true  \
    enforce_hostnames=false \
    require_cn=false \
    allowed_uri_sans="spiffe://*" \
    max_ttl=72h

# Cluster2
$ vault write pki_int2/roles/istio-ca2 \
    allowed_domains=istio-ca \
    allow_any_name=true  \
    enforce_hostnames=false \
    require_cn=false \
    allowed_uri_sans="spiffe://*" \
    max_ttl=72h

# The role, istio-ca, is a logical name that maps to a policy used to generate credentials. This generates a number of endpoints that are used by the Kubernetes service account to issue and sign these certificates. A policy must be created that enables these paths.

# Create a policy named pki-istio-ca that enables read access to the PKI secrets engine paths.

$ vault policy write pki-istio-ca - <<EOF
path "pki*"                        { capabilities = ["read", "list"] }
path "pki_int1/roles/istio-ca1"   { capabilities = ["create", "update"] }
path "pki_int1/sign/istio-ca1"    { capabilities = ["create", "update"] }
path "pki_int1/issue/istio-ca1"   { capabilities = ["create"] }
path "pki_int2/roles/istio-ca2"   { capabilities = ["create", "update"] }
path "pki_int2/sign/istio-ca2"    { capabilities = ["create", "update"] }
path "pki_int2/issue/istio-ca2"   { capabilities = ["create"] }
EOF

# These paths enable the token to view all the roles created for this PKI secrets engine and access the sign and issues operations for the istio-ca roles.

```