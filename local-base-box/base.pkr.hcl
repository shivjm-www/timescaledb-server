# Adapted (and borrowed) from <https://github.com/microsoft/MSLab-templates/blob/48109b672dad7599d62c9771d22ce5711274e04e/templates/debian-11/debian-11.pkr.hcl>.

packer {
  required_plugins {
    hyperv = {
      version = ">= 1.0.4"
      source  = "github.com/hashicorp/hyperv"
    }
  }
}

variable "username" {
  type    = string
  default = "packer"
}

variable "password" {
  type    = string
  default = "packer"
  sensitive = true
}

variable "domain" {
  type    = string
  default = "corp.something.com"
}

variable "vm_name" {
  type    = string
  default = "debian11-ansible"
}

variable "vm_dir" {
  type    = string
  default = ".output"
}

variable "iso_url" {
  type    = string
  default = "https://cdimage.debian.org/cdimage/release/11.4.0/amd64/iso-cd/debian-11.4.0-amd64-netinst.iso"
}

variable "iso_checksum" {
  type = string
  default = "d490a35d36030592839f24e468a5b818c919943967012037d6ab3d65d030ef7f"
}

variable "osdisk_size" { 
  type    = number
  default = 4096
}

variable "local_server" {
  type = string
  default = "{{ .HTTPIP }}"
}

variable "local_port" {
  type = string
  default = "{{ .HTTPPort }}"
}

variable "switch_name" {
  type    = string
  default = "Default Switch"
}

source "hyperv-iso" "debian-11" {
  boot_command      = ["<esc><wait>", "install <wait>", "auto=true ", "preseed/url=http://${var.local_server}:${var.local_port}/preseed.cfg ", "passwd/user-password=${var.password} ", "passwd/user-password-again=${var.password} ", "passwd/username=${var.username} ", "hostname=${var.vm_name} ", "hw-detect/start_pcmcia=false", "domain=${var.domain} ", "interface=auto ", "vga=788 noprompt quiet --<enter>", "console-setup/ask_detect=false <wait>", "console-keymaps-at/keymap=us <wait>", "kbd-chooser/method=us <wait>", "keyboard-configuration/xkb-keymap=us <wait>"]
  boot_wait         = "3s"
  generation        = 2
  # headless          = true
  http_directory    = "${path.root}/http"
  iso_checksum      = var.iso_checksum
  iso_url           = var.iso_url
  output_directory  = var.vm_dir
  shutdown_command  = "echo '${var.password}' | sudo -S shutdown -P now"
  ssh_password      = var.password
  ssh_timeout       = "30m"
  ssh_username      = var.username
  switch_name       = var.switch_name
  vm_name           = "packer-${var.vm_name}"
  differencing_disk = true
  disk_size         = var.osdisk_size
  disk_block_size   = 1 # 1MB as per https://docs.microsoft.com/en-us/windows-server/virtualization/hyper-v/best-practices-for-running-linux-on-hyper-v#tuning-linux-file-systems-on-dynamic-vhdx-files
}


build {
  sources = ["source.hyperv-iso.debian-11"]

  # Enable passwordless sudo.
  provisioner "shell" {
    execute_command  = "echo ${var.password} | {{.Vars}} sudo -S bash -c {{.Path}}"
    inline = [
      "echo '${var.username} ALL=(ALL) NOPASSWD: ALL' | tee /etc/sudoers.d/${var.username}",
      "chmod 440 /etc/sudoers.d/${var.username}",
      "ls -l /etc/sudoers.d"
    ]
  }

  provisioner "shell" {
    scripts = [
      "../scripts/ansible.sh"
    ]

    execute_command = "echo '{{ .ssh_username }}' | {{.Vars}} sudo -S -E bash '{{.Path}}'"
  }
}
