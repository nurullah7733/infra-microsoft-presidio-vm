variable "hcloud_token" {
  type      = string
  sensitive = true
}

variable "ssh_key_name" {
  type = string
}

variable "server_type" {
  type = string
}

variable "domain" {
  type    = string
  default = "example.com"
}

variable "email" {
  type    = string
  default = "you@example.com"
}

variable "locations" {
  type = list(string)
  default = ["fsn1", "hel1", "nbg1", "sgp1"]
}

variable "hetznerdns_token" {
  type      = string
  sensitive = true
}
variable "monitoring_vm_ip" {
  type      = string
  sensitive = true
}

 