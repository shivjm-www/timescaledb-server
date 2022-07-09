packer {
  required_plugins {
    digitalocean = {
      version = ">= 1.0.0"
      source  = "github.com/hashicorp/digitalocean"
    }
  }
}

variable "vagrant_base_box" {
  type = string
  # default = "geerlingguy/debian11"
  default = "trombik/ansible-debian-11-amd64"
}

variable "do_token" {
  type = string
  sensitive = true
}

variable "do_region" {
  type = string
}

variable "do_droplet_size" {
  type = string
  description = "Size of Droplet to use to build image."
  default = "c-4"
}

variable "do_base_image" {
  type = string
  default = "debian-11-x64"
}

source "vagrant" "tsdb_server_local" {
  source_path = var.vagrant_base_box
  provider = "virtualbox"
  communicator = "ssh"
  ssh_username = "vagrant"
  ssh_password = "vagrant"
  output_dir = ".tsdb-server-local"
}

source "digitalocean" "tsdb_server" {
  api_token = var.do_token
  region = var.do_region
  size = var.do_droplet_size
  image = var.do_base_image
  private_networking = true
  tags = ["packer", "packer-building"]
  ssh_username = "root"
}

build {
  name = "tsdb_server_vagrant_local"

  sources = [
    "source.vagrant.tsdb_server_local",
    "source.digitalocean.tsdb_server"
  ]

  provisioner "shell" {
    scripts = [
      "./scripts/ansible.sh"
    ]

    execute_command = "echo '{{ .ssh_username }}' | {{.Vars}} sudo -S -E bash '{{.Path}}'"

    only = ["digitalocean.tsdb_server"]
  }

  provisioner "ansible-local" {
    playbook_file = "./ansible/main.yml"
    playbook_dir = "./ansible"
  }
}
