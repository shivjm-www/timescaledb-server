variable "vagrant_base_box" {
  type = string
  default = "geerlingguy/debian11"
}

source "vagrant" "tsdb_server" {
  source_path = var.vagrant_base_box
  provider = "virtualbox"
  communicator = "ssh"
  ssh_username = "vagrant"
  ssh_password = "vagrant"
}

build {
  name = "tsdb_server_vagrant"

  sources = [
    "source.vagrant.tsdb_server"
  ]

  provisioner "shell" {
    scripts = [
      "./scripts/ansible.sh"
    ]

    execute_command = "echo 'vagrant' | {{.Vars}} sudo -S -E bash '{{.Path}}'"
  }

  provisioner "ansible-local" {
    playbook_file = "./ansible/main.yml"
    playbook_dir = "./ansible"
  }
}
