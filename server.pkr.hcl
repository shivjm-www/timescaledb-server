packer {
  required_plugins {
    digitalocean = {
      version = ">= 1.0.0"
      source  = "github.com/hashicorp/digitalocean"
    }
  }
}

variable "hyperv_base_vmcx" {
  type        = string
  description = "Base Hyper-V machine with Debian 11 and Ansible. (Must be path to export directory, not .vmcx file.)"
  default     = "./debian11-ansible-vm"
}

variable "hyperv_switch" {
  type    = string
  default = "Default Switch"
}

variable "do_token" {
  type      = string
  sensitive = true
}

variable "do_region" {
  type = string
}

variable "do_droplet_size" {
  type        = string
  description = "Size of Droplet to use to build image."
  default     = "c-4"
}

variable "do_base_image" {
  type    = string
  default = "debian-11-x64"
}

variable "pgbackrest_cipher_pass" {
  type = string
}

variable "pgbackrest_s3_bucket" {
  type = string
}

variable "pgbackrest_s3_endpoint" {
  type = string
}

variable "pgbackrest_s3_region" {
  type = string
}

variable "pgbackrest_s3_key" {
  type = string
}

variable "pgbackrest_s3_key_secret" {
  type = string
}

source "hyperv-vmcx" "tsdb_server_local" {
  clone_from_vmcx_path  = var.hyperv_base_vmcx
  ssh_username          = "box"
  ssh_password          = "box"
  shutdown_command      = "echo 'box' | sudo -S shutdown -P now"
  guest_additions_mode  = "none"
  headless              = true
  communicator          = "ssh"
  generation            = 2
  enable_dynamic_memory = true
  disk_block_size       = 1
  switch_name           = var.hyperv_switch
}

source "digitalocean" "tsdb_server" {
  api_token          = var.do_token
  region             = var.do_region
  size               = var.do_droplet_size
  image              = var.do_base_image
  private_networking = true
  tags               = ["packer", "packer-building"]
  ssh_username       = "root"
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
    playbook_dir  = "./ansible"

    extra_arguments = [
      "--extra-vars", "\"pgbackrest_cipher_pass=${var.pgbackrest_cipher_pass}\"",
      "--extra-vars", "\"pgbackrest_s3_bucket=${var.pgbackrest_s3_bucket}\"",
      "--extra-vars", "\"pgbackrest_s3_endpoint=${var.pgbackrest_s3_endpoint}\"",
      "--extra-vars", "\"pgbackrest_s3_region=${var.pgbackrest_s3_region}\"",
      "--extra-vars", "\"pgbackrest_s3_key=${var.pgbackrest_s3_key}\"",
      "--extra-vars", "\"pgbackrest_s3_key_secret=${var.pgbackrest_s3_key_secret}\"",
    ]
  }
}
