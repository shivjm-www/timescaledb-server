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
  preseed = templatefile("${path.root}/http/preseed.cfg", {
    root_password = var.root_password,
    username      = var.username,
    password      = var.password,
  })
  shutdown_command     = "echo '${var.password}' | sudo -S shutdown -P now"
  guest_additions_path = "/tmp/VBoxGuestAdditions.iso"
}

variable "do_token" {
  type        = string
  sensitive   = true
  description = "API token for accessing DigitalOcean (required for import)."
}

variable "do_region" {
  type        = string
  sensitive   = true
  description = "DigitalOcean region to store image in when importing."
}

variable "do_image_name" {
  type    = string
  default = "packer-timescaledb"
}

variable "do_spaces_key" {
  type        = string
  description = "DigitalOcean Spaces access key (for temporary upload)."
  sensitive   = true
}

variable "do_spaces_secret_key" {
  type        = string
  description = "DigitalOcean Spaces secret access key (for temporary upload)."
  sensitive   = true
}

variable "do_spaces_bucket" {
  type        = string
  description = "DigitalOcean Spaces bucket (for temporary upload)."
  sensitive   = true
}

variable "do_image_tags" {
  type        = list(string)
  default     = ["packer", "timescaledb", "promscale", "pgbackrest"]
  description = "Tags to apply to DigitalOcean Custom Image."
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
  type        = number
  default     = 8192
  description = "Initial size of hard disk in megabytes. Must be at least 5 GB. Will be shrunk to match used space as last step."
}

variable "hyperv_switch" {
  type        = string
  description = "Name of network switch to use when building in Hyper-V. Must be bridged. Default switch will not work."
}

variable "headless" {
  type        = bool
  default     = true
  description = "Whether to hide builder GUI. Must be `true` in CI environments."
}

variable "root_password" {
  type        = string
  sensitive   = true
  description = "Desired root password. Used for `sudo`."
}

variable "username" {
  type        = string
  description = "Name of primary user to create during installation. Will have `sudo` privileges."
}

variable "password" {
  type        = string
  sensitive   = true
  description = "Password for user created during installation."
}

variable "skip_virtualbox_export" {
  type    = bool
  default = false
}

# Adapted from <https://github.com/geerlingguy/packer-boxes/blob/55412993a04d3d81ee0a61559cfd993e6d0907ad/debian11/box-config.json>.
source "hyperv-iso" "tsdb" {
  iso_url          = var.debian_iso_url
  iso_checksum     = var.debian_iso_checksum
  output_directory = ".output/hyperv"
  disk_size        = var.disk_size
  disk_block_size  = 32
  switch_name      = var.hyperv_switch

  # Generation 2 machines use UEFI, which triggers different behaviour
  # from the Debian installer.
  generation = 1

  headless         = var.headless
  shutdown_command = local.shutdown_command
  ssh_username     = var.username
  ssh_password     = var.password

  boot_command = local.boot_command

  # Sometimes it’s ready in five seconds, sometimes it’s ready in 30.
  # Better to be safe.
  boot_wait        = "45s"
  ssh_wait_timeout = "10m"

  http_content = {
    "/preseed.cfg" = local.preseed,
  }
}

source "virtualbox-iso" "ci" {
  iso_url          = var.debian_iso_url
  iso_checksum     = var.debian_iso_checksum
  guest_os_type    = "Debian_64"
  output_directory = ".output/vb"
  shutdown_command = local.shutdown_command
  disk_size        = var.disk_size
  headless         = var.headless
  http_content = {
    "/preseed.cfg" = local.preseed
  }
  ssh_username = var.username
  ssh_password = var.password
  ssh_timeout  = "20m"
  boot_wait    = "30s"
  boot_command = local.boot_command
  vboxmanage = [
    ["modifyvm", "{{.Name}}", "--memory", "1024"],
    ["modifyvm", "{{.Name}}", "--cpus", "1"]
  ]
  hard_drive_discard       = true
  hard_drive_nonrotational = true
  guest_additions_path     = local.guest_additions_path
  skip_export              = var.skip_virtualbox_export
}

build {
  name = "tsdb"

  sources = [
    "source.hyperv-iso.tsdb",
    "source.virtualbox-iso.ci"
  ]

  provisioner "shell" {
    execute_command = "echo '${var.password}' | {{.Vars}} sudo -SE bash '{{.Path}}'"
    script          = "scripts/setup.sh"
    env = {
      USERNAME = var.username
    }
  }

  provisioner "shell" {
    inline = [
      "echo '${var.password}' | {{.Vars}} sudo -SE bash '{{.Path}}'"
    ]
    env = {
      ISO_PATH = local.guest_additions_path
    }
    only = ["source.virtualbox-iso.ci"]
  }

  provisioner "shell" {
    execute_command = "echo '${var.password}' | {{.Vars}} sudo -SE bash '{{.Path}}'"
    script          = "scripts/ansible.sh"
  }

  provisioner "ansible-local" {
    playbook_file           = "./ansible/main.yml"
    playbook_dir            = "./ansible"
    galaxy_file             = "./ansible/meta/requirements.yml"
    clean_staging_directory = true
  }

  provisioner "shell" {
    execute_command = "echo '${var.password}' | {{.Vars}} sudo -SE bash '{{.Path}}'"
    script          = "scripts/cleanup.sh"
    env = {
      ISO_PATH = local.guest_additions_path
    }
  }

  post-processor "digitalocean-import" {
    api_token         = var.do_token
    spaces_key        = var.do_spaces_key
    spaces_secret     = var.do_spaces_secret_key
    spaces_region     = var.do_region
    space_name        = var.do_spaces_bucket
    image_name        = "${var.do_image_name}-${local.starttime}"
    image_description = "TimescaleDB, Promscale, and pgBackRest. Placeholders in configuration files. Run `timescaledb-tune --yes` in new Droplets."
    image_regions     = [var.do_region]
    image_tags        = var.do_image_tags

    # The image can take a long time to become available.
    timeout = "60m"
  }
}
