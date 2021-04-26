seal "transit" {
  address         = "${vault_addr}"
  namespace       = "admin"
  disable_renewal = "false"
  key_name        = "autounseal"
  mount_path      = "transit/"
  tls_skip_verify = "true"
  token           = "${vault_token}"
}