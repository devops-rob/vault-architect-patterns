output "token" {
  value     = vault_token.autounseal.client_token
  sensitive = true
}

output "stanza" {
  value     = data.template_file.seal_stanza.rendered
  sensitive = true
}