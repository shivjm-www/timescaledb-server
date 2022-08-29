# timescaledb-server

A Packer template for building [a DigitalOcean Custom Image](https://docs.digitalocean.com/products/images/custom-images/) using [VirtualBox](https://www.virtualbox.org/) that includes these components:

* [TimescaleDB](https://www.timescale.com/) with the default configuration
* [The Promscale extension](https://www.timescale.com/promscale)
* [pgBackRest](https://pgbackrest.org/) with a placeholder configuration
* [node_exporter](https://github.com/prometheus/node_exporter) listening on port 9100
* [postgres_exporter](https://github.com/prometheus-community/postgres_exporter/) listening on port 9187
* [Promtail](https://grafana.com/docs/loki/latest/clients/promtail/)…
  * Listening for logs on port 3100
  * Collecting logs from /var/log, syslog (via rsyslog) & journald; and
  * Configured to forward all logs to an unspecified Loki instance

Some of these must be configured through [user data](https://docs.digitalocean.com/products/droplets/how-to/provide-user-data/) or other means when deployed. The easiest way is via [the builtin envsubst tool](https://manpages.debian.org/bullseye/gettext-base/envsubst.1.en.html).

To skip the DigitalOcean import (leaving the VM as an appliance that can be imported into VirtualBox), use <kbd>-except</kbd>:

```bash
packer build -except=digitalocean-import server.pkr.hcl
```

# Development

The CI builds fail frequently thanks to [rate limiting on GitHub’s end](https://github.com/hashicorp/packer/issues/11259), despite the workflows specifying `PACKER_GITHUB_API_TOKEN`. There’s nothing to be done except wait and retry.

# Acknowledgements

Parts of this repository are modelled after [Jeff Geerling’s excellent packer-boxes repository](https://github.com/geerlingguy/packer-boxes) and [tsugliani/packer-vsphere-debian-appliances](https://github.com/tsugliani/packer-vsphere-debian-appliances).
