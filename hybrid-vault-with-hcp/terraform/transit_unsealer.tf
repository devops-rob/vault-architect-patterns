provider "vault" {
  address   = var.vault_addr
  token     = var.vault_token
  namespace = var.namespace
}

module "transit_autounsealer" {
  source = "devops-rob/transit-secrets-engine/vault"

  transit_keys = [
    {
      name                   = "autounseal"
      allow_plaintext_backup = false
      convergent_encryption  = false
      exportable             = false
      deletion_allowed       = true
      derived                = false
      type                   = "rsa-2048"
      min_decryption_version = 1
      min_encryption_version = 1
    }
  ]
}

resource "vault_policy" "autounseal" {
  name = "autounseal"

  policy = <<EOF
path "transit/encrypt/autounseal" {
   capabilities = [ "update" ]
}

path "transit/decrypt/autounseal" {
   capabilities = [ "update" ]
}
EOF
}

resource "vault_token" "autounseal" {
  policies = [ "autounseal" ]
  depends_on = [
    vault_policy.autounseal
  ]
}

data "template_file" "seal_stanza" {
  template = "${file("${path.module}/seal_stanza.tpl")}"

  vars = {
    vault_addr  = var.vault_addr
    vault_token = var.vault_token
    namespace   = var.namespace
  }
}

resource "local_file" "seal_stanza" {
  filename          = "${path.module}/seal_stanza.hcl"
  sensitive_content = data.template_file.seal_stanza.rendered
}