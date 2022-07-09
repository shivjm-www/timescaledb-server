variable "vagrant_base_box" {
  type = string
  # default = "geerlingguy/debian11"
  default = "trombik/ansible-debian-11-amd64"
}

source "vagrant" "tsdb_server_local" {
  source_path = var.vagrant_base_box
  provider = "virtualbox"
  communicator = "ssh"
  ssh_username = "vagrant"
  ssh_password = "vagrant"
  output_dir = ".tsdb-server-local"
}

build {
  name = "tsdb_server_vagrant_local"

  sources = [
    "source.vagrant.tsdb_server_local"
  ]

  # Not needed with the Ansible-enabled base image.
  # provisioner "shell" {
  #   scripts = [
  #     "./scripts/ansible.sh"
  #   ]

  #   execute_command = "echo 'vagrant' | {{.Vars}} sudo -S -E bash '{{.Path}}'"
  # }

  provisioner "ansible-local" {
    playbook_file = "./ansible/main.yml"
    playbook_dir = "./ansible"
  }
}
