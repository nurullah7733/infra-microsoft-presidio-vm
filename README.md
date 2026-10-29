# Presidio on Hetzner Cloud

Terraform configuration for provisioning a Hetzner Cloud VM and deploying the
official [Presidio](https://github.com/data-privacy-stack/presidio) project
with Docker Compose. Cloud-init configures the VM, reverse proxy, TLS, and
optional monitoring integrations on first boot.

> **Portfolio/demo configuration:** Replace the example domain, email, and
> monitoring IP with values you own before deploying. Never commit API tokens,
> Terraform state, or your local `terraform.tfvars`.

## Features

- Provisions a Hetzner Cloud server, firewall, SSH key, and floating IPv4
  address with Terraform.
- Creates a `presidio` DNS A record in an existing Hetzner DNS zone.
- Installs the official Presidio Docker Compose stack from its public GitHub
  repository.
- Routes HTTP traffic through Nginx to the Presidio Analyzer API.
- Requests a Let's Encrypt certificate and schedules certificate renewal when
  a real domain and email are configured.
- Installs Prometheus Node Exporter, cAdvisor, and Promtail for optional
  monitoring and Loki log forwarding.
- Ignores Terraform state, local variable files, plans, and provider downloads
  through the project `.gitignore`.

## Requirements

- A Hetzner Cloud account and API token.
- A Hetzner DNS API token and an existing DNS zone managed by Hetzner DNS.
- Terraform installed locally.
- An SSH public key at `~/.ssh/vm-deploy-key.pub` (the matching private key
  stays on your computer). Terraform expands `~` to your home directory.
- A monitoring VM public IP address. Promtail sends logs to this IP's Loki
  endpoint on port `3100`.
- A domain you control if you want DNS and automatic TLS to work.

## Setup

1. Clone this repository and open a terminal in its `terraform` directory.
2. If you do not already have a deployment key, generate one:

   ```sh
   ssh-keygen -t ed25519 -f ~/.ssh/vm-deploy-key
   ```

   Keep the private key local; Terraform uploads only the `.pub` public key.
3. Create a local variable file from the example:

   ```sh
   cp terraform.tfvars.example terraform.tfvars
   ```

   On PowerShell, use:

   ```powershell
   Copy-Item terraform.tfvars.example terraform.tfvars
   ```

4. Edit `terraform.tfvars`:

   | Variable | Value |
   | --- | --- |
   | `hcloud_token` | Your Hetzner Cloud API token. |
   | `hetznerdns_token` | Your Hetzner DNS API token. |
   | `ssh_key_name` | A name for the SSH public key registered in Hetzner. |
   | `server_type` | A Hetzner server type available in the selected location. |
   | `domain` | The apex domain of an existing Hetzner DNS zone, for example `example.com`. Terraform creates `presidio.<domain>`. |
   | `email` | Your email address for Let's Encrypt certificate registration. |
   | `locations` | Use a single location, for example `["nbg1"]`. |
   | `monitoring_vm_ip` | The monitoring VM's IPv4 address, without a CIDR suffix. Replace the documentation-only example IP. |

5. Confirm the DNS zone exists in your Hetzner account and that the
   `presidio.<domain>` hostname can point to the VM's floating IP.
6. Initialize, review, and apply the configuration:

   ```sh
   terraform init
   terraform fmt -check
   terraform validate
   terraform plan
   terraform apply
   ```

   Review the plan before confirming. Hetzner Cloud resources may incur charges.

7. After cloud-init finishes, open `https://presidio.<domain>` to reach the
   Presidio Analyzer API. If using the example domain or email, Certbot is
   intentionally skipped; use the VM's floating IP over HTTP for a demo, or
   configure a real domain and email for HTTPS.

Terraform prints the server IPv4 addresses and floating IP after deployment.
Cloud-init logs on the VM are available in `/var/log/cloud-init-output.log`.

## Network and monitoring

The firewall allows SSH (`22`), HTTP (`80`), and HTTPS (`443`) from the
internet. Monitoring ports are restricted to `monitoring_vm_ip`:

| Port | Service |
| --- | --- |
| `5001` | Presidio Anonymizer API |
| `5002` | Presidio Analyzer API |
| `8080` | cAdvisor |
| `9080` | Promtail |
| `9100` | Prometheus Node Exporter |

Promtail forwards logs to `http://<monitoring_vm_ip>:3100/loki/api/v1/push`.
Ensure the monitoring VM accepts the relevant traffic from the Presidio VM.

## Important notes

- **Single-location deployment:** Configure exactly one value in `locations`.
  The current cloud-init template assigns the first floating IP to each VM,
  so deploying multiple locations is not supported by this configuration.
- **DNS prerequisites:** The domain must be an existing Hetzner DNS zone, and
  its nameservers must be set up for public DNS resolution. DNS propagation is
  required before Let's Encrypt can issue a certificate.
- **API, not a web UI:** Nginx proxies requests to the Presidio Analyzer API;
  this deployment does not add a separate frontend.
- **First boot:** Cloud-init builds and starts the Presidio containers. Initial
  provisioning may take several minutes.
- **Cost and cleanup:** Review Hetzner resource pricing before applying. To
  remove resources managed by this Terraform configuration, run
  `terraform destroy` from the `terraform` directory and review its plan.
- **Keep secrets local:** `terraform.tfvars`, Terraform state, and plan files
  may contain sensitive information. Keep them out of source control and use
  least-privilege provider tokens.

## Project layout

```text
.
├── cloud-init/
│   └── app.yaml
└── terraform/
    ├── main.tf
    ├── outputs.tf
    ├── providers.tf
    ├── terraform.tfvars.example
    └── variables.tf
```
