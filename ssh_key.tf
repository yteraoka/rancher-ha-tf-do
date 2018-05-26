resource "digitalocean_ssh_key" "key" {
  name = "rke terraform"
  public_key = "${file(var.public_key_path)}"
}
