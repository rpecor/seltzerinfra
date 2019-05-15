variable "digitalocean_token" {}
variable "pvt_key" {}

provider "digitalocean" {
  token = "${var.digitalocean_token}"
}

data "digitalocean_ssh_key" "ryan" {
  name = "Ryan Macbook"
}

resource "digitalocean_droplet" "nginx_server" {
  name               = "trippedup-server"
  image              = "ubuntu-16-04-x64"
  size               = "512mb"
  region             = "nyc1"
  ipv6               = true
  private_networking = false
  ssh_keys           = ["${data.digitalocean_ssh_key.ryan.fingerprint}"]

  connection {
    user        = "root"
    type        = "ssh"
    private_key = "${file(var.pvt_key)}"
    timeout     = "2m"
  }

  provisioner "remote-exec" {
    inline = [
      "export PATH=$PATH:/usr/bin",

      # install nginx
      "sudo apt-get update",

      "sudo apt-get -y install nginx",
      "curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo apt-key add - ",
      "sudo add-apt-repository 'deb [arch=amd64] https://download.docker.com/linux/ubuntu $(lsb_release -cs) stable'",
      "sudo apt-get update",
      "apt-cache policy docker-ce",
      "sudo apt-get install -y docker-ce",
      "git clone https://github.com/rpecor/seltzeradvocate.git",
      "sudo apt -y install docker-compose",
    ]
  }
}

resource "digitalocean_domain" "default" {
  name       = "seltzeradvocate.com"
  ip_address = "${digitalocean_droplet.nginx_server.ipv4_address}"
}

resource "digitalocean_record" "CNAME-www" {
  domain = "${digitalocean_domain.default.name}"
  type   = "CNAME"
  name   = "www"
  value  = "@"
}
