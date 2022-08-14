packer {
  required_plugins {
    digitalocean = {
      version = ">= 1.0.0"
      source  = "github.com/hashicorp/digitalocean"
    }
  }
}

locals {
  starttime = formatdate("YYYYMMDDhhmmss", timestamp())
}

variable "do_token" {
  type      = string
  sensitive = true
}

variable "do_region" {
  type = string
}

variable "do_image_name" {
  type    = string
  default = "packer-timescaledb"
}

variable "do_spaces_key" {
  type        = string
  description = "Spaces access key (for temporary upload)."
}

variable "do_spaces_secret_key" {
  type        = string
  description = "Spaces secret access key (for temporary upload)."
}

variable "do_spaces_bucket" {
  type        = string
  description = "Spaces bucket (for temporary upload)."
}

variable "do_droplet_size" {
  type        = string
  description = "Size of Droplet to use to build image. Sets the disk size of the image (minimum for future Droplets)."
  default     = "c-2" # The highest you can go without increasing the disk size.
}

variable "do_base_image" {
  type    = string
  default = "debian-11-x64"
}

variable "debian_iso_url" {
  type    = string
  default = "https://cdimage.debian.org/cdimage/release/11.4.0/amd64/iso-cd/debian-11.4.0-amd64-netinst.iso"
}

variable "debian_iso_checksum" {
  type    = string
  default = "sha256:d490a35d36030592839f24e468a5b818c919943967012037d6ab3d65d030ef7f"
}

variable "disk_size" {
  type    = number
  default = 8192
}

variable "vm_name" {
  type    = string
  default = "packer-tsdb"
}

variable "switch_name" {
  type = string
}

variable "headless" {
  type    = bool
  default = true
}

variable "root_password" {
  type      = string
  sensitive = true
}

variable "username" {
  type      = string
  sensitive = true
}

variable "password" {
  type      = string
  sensitive = true
}

# Adapted from <https://github.com/geerlingguy/packer-boxes/blob/55412993a04d3d81ee0a61559cfd993e6d0907ad/debian11/box-config.json>.
source "hyperv-iso" "tsdb" {
  iso_url      = var.debian_iso_url
  iso_checksum = var.debian_iso_checksum

  output_directory = ".output/tsdb"
  disk_size        = var.disk_size
  disk_block_size  = 32
  vm_name          = var.vm_name
  switch_name      = var.switch_name
  generation       = 1
  headless         = var.headless
  shutdown_command = "echo '${var.password}' | sudo -S shutdown -P now"
  ssh_username     = var.username
  ssh_password     = var.password

  boot_command = [
    "<esc><wait><wait>",
    "install <wait>",
    " preseed/url=http://{{ .HTTPIP }}:{{ .HTTPPort }}/preseed.cfg <wait>",
    "debian-installer=en_US.UTF-8 <wait>",
    "auto <wait>",
    "locale=en_US.UTF-8 <wait>",
    "kbd-chooser/method=us <wait>",
    "keyboard-configuration/xkb-keymap=us <wait>",
    "netcfg/get_hostname={{ .Name }} <wait>",
    "netcfg/get_domain=vagrantup.com <wait>",
    "fb=false <wait>",
    "debconf/frontend=noninteractive <wait>",
    "console-setup/ask_detect=false <wait>",
    "console-keymaps-at/keymap=us <wait>",
    "grub-installer/bootdev=/dev/sda <wait>",
    "<enter><wait>",
  ]
  # Sometimes it’s ready in five seconds, sometimes it’s ready in 30.
  # Better to be safe.
  boot_wait        = "30s"
  ssh_wait_timeout = "600s"
  http_content = {
    "/preseed.cfg" = templatefile("${path.root}/http/preseed.cfg", {
      root_password = var.root_password,
      username      = var.username,
      password      = var.password,
    }),
  }
}

build {
  name = "tsdb"

  sources = [
    "source.hyperv-iso.tsdb"
  ]

  provisioner "shell" {
    execute_command = "echo '${var.password}' | {{.Vars}} sudo -SE bash '{{.Path}}'"
    script          = "scripts/setup.sh"
    env = {
      USERNAME = var.username
    }
  }

  provisioner "shell" {
    execute_command = "echo '${var.password}' | {{.Vars}} sudo -SE bash '{{.Path}}'"
    script          = "scripts/ansible.sh"
  }

  provisioner "ansible-local" {
    playbook_file = "./ansible/main.yml"
    playbook_dir  = "./ansible"
  }

  provisioner "shell" {
    execute_command = "echo '${var.password}' | {{.Vars}} sudo -SE bash '{{.Path}}'"
    script          = "scripts/cleanup.sh"
  }

  post-processor "digitalocean-import" {
    api_token           = var.do_token
    spaces_key          = var.do_spaces_key
    spaces_secret       = var.do_spaces_secret_key
    spaces_region       = var.do_region
    space_name          = var.do_spaces_bucket
    image_name          = "${var.do_image_name}-${local.starttime}"
    image_description   = "Packer import {{timestamp}}"
    image_regions       = [var.do_region]
    image_tags          = ["custom", "packer", "bastion"]
    keep_input_artifact = true
  }
}
