# timescaledb-server

A Packer template for building [a DigitalOcean Custom Image](https://docs.digitalocean.com/products/images/custom-images/) that includes [TimescaleDB](https://www.timescale.com/) with [the Promscale extension](https://www.timescale.com/promscale) and [pgBackRest](https://pgbackrest.org/). These components must be configured through [user data](https://docs.digitalocean.com/products/droplets/how-to/provide-user-data/) or other means at the time of creation of a Droplet.

There are two builds: one using Hyper-V for efficient local builds on Windows, and one using VirtualBox for all other platforms (including CI). These are prepared identically save for handling guest additions. Only one should be built at time, e.g.:

```bash
packer build -only='*.ci' -var-file my-vars.pkr.hcl server.pkr.hcl
```

# Development

The CI builds fail sporadically because of [rate limiting on GitHub’s end](https://github.com/hashicorp/packer/issues/11259), despite the workflows specifying `PACKER_GITHUB_API_TOKEN`. There is nothing to be done except wait and retry.

# Acknowledgements

Parts of this repository are modelled after [Jeff Geerling’s excellent packer-boxes repository](https://github.com/geerlingguy/packer-boxes) and [tsugliani/packer-vsphere-debian-appliances](https://github.com/tsugliani/packer-vsphere-debian-appliances).
