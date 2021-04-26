#!/bin/bash

echo "Enter Vault token for HCP Vault deployment"
read hcpVaultToken

echo "Enter url for HCP Vault"
read hcpVaultAddr

# Enable Transit secrets engine

sepayload='
{
  "type": "transit",
  "config": {
    "force_no_cache": true
  }
}
'

curl \
    --header "X-Vault-Token: $hcpVaultToken" \
    --header "X-Vault-Namespace: admin" \
    --request POST \
    --data "$sepayload" \
    $hcpVaultAddr/v1/sys/mounts/transit

# Create a Transit key

tkpayload='
{
  "type": "aes256-gcm96",
  "derived": false
}
'

curl \
    --header "X-Vault-Token: $hcpVaultToken" \
    --header "X-Vault-Namespace: admin" \
    --request POST \
    --data "$tkpayload" \
    $hcpVaultAddr/v1/transit/keys/autounseal

# Create autounseal policy

policy='
{
    "policy": "path \"transit/encrypt/autounseal\" { \n capabilities = [\"update\"]\n} \n\npath \"transit/decrypt/autounseal\" {\n capabilities = [\"update\"]\n}"
}
'

curl \
    --header "X-Vault-Token: $hcpVaultToken" \
    --header "X-Vault-Namespace: admin" \
    --request PUT \
    --data "$policy" \
    $hcpVaultAddr/v1/sys/policy/autounseal

# Create a client token

tpayload='
{
  "policies": ["autounseal"],
  "ttl": "768h",
  "renewable": true,
  "no_parent": true,
  "display_name": "autounseal_token"
}
'

unsealToken=$(curl \
    --header "X-Vault-Token: $hcpVaultToken" \
    --header "X-Vault-Namespace: admin" \
    --request POST \
    --data "$tpayload" \
    $hcpVaultAddr/v1/auth/token/create |\
    jq -r .auth.client_token)

# Create seal stanza template 

tee seal_stanza.hcl <<EOF
seal "transit" {
  address         = "$hcpVaultAddr"
  namespace       = "admin/"
  disable_renewal = "false"
  key_name        = "autounseal"
  mount_path      = "transit/"
  tls_skip_verify = "true"
  token           = "$unsealToken"
}
EOF
