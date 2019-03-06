resource "digitalocean_droplet" "node" {
  count = "${var.number_of_node}"
  image = "${var.droplet_image}"
  name = "rke-${count.index}"
  region = "${var.region}"
  size = "s-1vcpu-2gb"
  ssh_keys = ["${digitalocean_ssh_key.key.id}"]
  monitoring = true
  user_data = "${file("userdata.sh")}"
}

resource "digitalocean_record" "rancher" {
  count = "${var.number_of_node}"
  domain = "${var.domain_suffix}"
  type = "A"
  name = "rancher"
  value = "${element(digitalocean_droplet.node.*.ipv4_address, count.index)}"
  ttl = 300
}

output "node0_address" {
  value = "${element(digitalocean_droplet.node.*.ipv4_address, 0)}"
}

output "node1_address" {
  value = "${element(digitalocean_droplet.node.*.ipv4_address, 1)}"
}

output "node2_address" {
  value = "${element(digitalocean_droplet.node.*.ipv4_address, 2)}"
}
