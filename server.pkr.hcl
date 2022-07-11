packer {
  required_plugins {
    digitalocean = {
      version = ">= 1.0.0"
      source  = "github.com/hashicorp/digitalocean"
    }
  }
}

variable "hyperv_base_vmcx" {
  type = string
  description = "Base Hyper-V machine with Debian 11 and Ansible. (Must be path to export directory, not .vmcx file.)"
  default = "./debian11-ansible-vm"
}

variable "hyperv_switch" {
  type = string
  default = "Default Switch"
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

source "hyperv-vmcx" "tsdb_server_local" {
  clone_from_vmcx_path = var.hyperv_base_vmcx
  ssh_username = "box"
  ssh_password = "box"
  shutdown_command = "echo 'box' | sudo -S shutdown -P now"
  guest_additions_mode = "none"
  headless = true
  keep_registered = true
  skip_export = true
  communicator = "ssh"
  generation = 2
  enable_dynamic_memory = true
  disk_block_size = 1
  switch_name = var.hyperv_switch
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
  name = "tsdb_server"

  sources = [
    "source.hyperv-vmcx.tsdb_server_local",
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
