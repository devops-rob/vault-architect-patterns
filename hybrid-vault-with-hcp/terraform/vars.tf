variable "vault_token" {
    sensitive = true
    description = "Vault token for HCP."
}

variable "vault_addr" {
  sensitive = true
  description = "URL for HCP Vault."
}

variable "namespace" {
  default = "admin/"
  description = "Namespace where the transit secrets engine will be configured."
}