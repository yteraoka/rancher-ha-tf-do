variable "private_key_path" {
  default = "id_rsa"
}

variable "public_key_path" {
  default = "id_rsa.pub"
}

variable "domain_suffix" {}

variable "region" {
  default = "sgp1"
}

variable "ssh_keys" {
  type = "list"
  default = ["16797382"]
}

variable "number_of_node" {
  default = 3
}
