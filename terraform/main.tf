
data "template_file" "cloud_init" {
  count    = length(var.locations)
  template = file("${path.module}/../cloud-init/app.yaml")

  vars = {
    floating_ip      = hcloud_floating_ip.ip[0].ip_address
    hostname         = "microsoft-presidio-${var.locations[count.index]}"
    monitoring_vm_ip = var.monitoring_vm_ip
    domain           = "presidio.${var.domain}"
    email            = var.email
  }
}

resource "hcloud_ssh_key" "default" {
  name       = var.ssh_key_name
  public_key = file(pathexpand("~/.ssh/vm-deploy-key.pub"))
}


resource "hcloud_server" "microsoft-presidio" {
  count         = length(var.locations)
  name          = "microsoft-presidio-${var.locations[count.index]}"
  server_type   = var.server_type
  image         = "ubuntu-22.04"
  location      = var.locations[count.index]
  ssh_keys    = [hcloud_ssh_key.default.id]  
  user_data = data.template_file.cloud_init[count.index].rendered
  firewall_ids  = [hcloud_firewall.microsoft-presidio.id]
}


resource "hcloud_firewall" "microsoft-presidio" {
  name = "allow-http-ssh-microsoft-presidio"

  rule {
    direction  = "in"
    protocol   = "tcp"
    port       = "22"
    source_ips = ["0.0.0.0/0", "::/0"]
  }

  rule {
    direction  = "in"
    protocol   = "tcp"
    port       = "80"
    source_ips = ["0.0.0.0/0", "::/0"]
  }

  rule {
    direction  = "in"
    protocol   = "tcp"
    port       = "443"
    source_ips = ["0.0.0.0/0", "::/0"]
  }

# for monigoring vm catch prometheus data using 9100 PORT
  rule {
    direction  = "in"
    protocol   = "tcp"
    port       = 9100
    source_ips = ["${var.monitoring_vm_ip}/32"]
  }

# for Container info catch by cAdvisor 8080 PORT
  rule {
    direction  = "in"
    protocol   = "tcp"
    port       = 8080
    source_ips = ["${var.monitoring_vm_ip}/32"]
  }

# for RAM, CPU, Disk info catch by promtail 9080 PORT
  rule {
    direction  = "in"
    protocol   = "tcp"
    port       = 9080
    source_ips = ["${var.monitoring_vm_ip}/32"]
  }

# anonymizer PORT
  rule {
    direction  = "in"
    protocol   = "tcp"
    port       = 5001
    source_ips = ["${var.monitoring_vm_ip}/32"]
  }

# analyzer PORT
  rule {
    direction  = "in"
    protocol   = "tcp"
    port       = 5002
    source_ips = ["${var.monitoring_vm_ip}/32"]
  }

# Redis PORT
  rule {
    direction  = "in"
    protocol   = "tcp"
    port       = 6379
    source_ips = ["${var.monitoring_vm_ip}/32"]
  }

}

resource "hcloud_floating_ip" "ip" {
  count         = length(var.locations)
  type          = "ipv4"
  home_location = var.locations[count.index]
}

resource "hcloud_floating_ip_assignment" "assign" {
  count          = length(var.locations)
  floating_ip_id = hcloud_floating_ip.ip[count.index].id
  server_id      = hcloud_server.microsoft-presidio[count.index].id
}

data "hetznerdns_zone" "main" {
  name = var.domain
}

resource "hetznerdns_record" "presidio" {
  zone_id = data.hetznerdns_zone.main.id
  name    = "presidio"
  type    = "A"
  value   = hcloud_floating_ip.ip[0].ip_address
  ttl     = 300
}
