# timescaledb-server

A Packer template for building [a DigitalOcean Custom Image](https://docs.digitalocean.com/products/images/custom-images/) using [VirtualBox](https://www.virtualbox.org/) that includes [TimescaleDB](https://www.timescale.com/) with [the Promscale extension](https://www.timescale.com/promscale) and [pgBackRest](https://pgbackrest.org/). These components must be configured through [user data](https://docs.digitalocean.com/products/droplets/how-to/provide-user-data/) or other means at the time of creation of a Droplet.

To skip the DigitalOcean import (leaving the VM as an appliance that can be imported into VirtualBox), use <kbd>-except</kbd>:

```bash
packer build -except=digitalocean-import server.pkr.hcl
```

# Development

The CI builds fail frequently thanks to [rate limiting on GitHub’s end](https://github.com/hashicorp/packer/issues/11259), despite the workflows specifying `PACKER_GITHUB_API_TOKEN`. There’s nothing to be done except wait and retry.

# Acknowledgements

Parts of this repository are modelled after [Jeff Geerling’s excellent packer-boxes repository](https://github.com/geerlingguy/packer-boxes) and [tsugliani/packer-vsphere-debian-appliances](https://github.com/tsugliani/packer-vsphere-debian-appliances).
