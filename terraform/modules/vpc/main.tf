resource "google_compute_network" "vpc" {
  name                    = "rohit-vpc"
  auto_create_subnetworks = false
  project                 = var.project_id
}

resource "google_compute_subnetwork" "subnet" {
  name          = "rohit-subnet"
  ip_cidr_range = "10.0.0.0/24"
  region        = var.region
  network       = google_compute_network.vpc.id
  project       = var.project_id

  private_ip_google_access = true
}

# VPC Connector — allows Cloud Run to reach Cloud SQL on the VPC
resource "google_vpc_access_connector" "connector" {
  name          = "rohit-vpc-connector"
  region        = var.region
  project       = var.project_id
  ip_cidr_range = "10.8.0.0/28"
  network       = google_compute_network.vpc.name

  min_throughput = 200
  max_throughput = 1000
}

# Private services access for Cloud SQL
resource "google_compute_global_address" "private_ip_range" {
  name          = "rohit-private-ip-range"
  purpose       = "VPC_PEERING"
  address_type  = "INTERNAL"
  prefix_length = 16
  network       = google_compute_network.vpc.id
  project       = var.project_id
}

resource "google_service_networking_connection" "private_vpc_connection" {
  network                 = google_compute_network.vpc.id
  service                 = "servicenetworking.googleapis.com"
  reserved_peering_ranges = [google_compute_global_address.private_ip_range.name]
}

# Firewall: deny all ingress by default, allow only VPC-internal traffic
resource "google_compute_firewall" "deny_all_ingress" {
  name    = "rohit-deny-all-ingress"
  network = google_compute_network.vpc.name
  project = var.project_id

  priority  = 65534
  direction = "INGRESS"

  deny { protocol = "all" }
  source_ranges = ["0.0.0.0/0"]
}

resource "google_compute_firewall" "allow_internal" {
  name    = "rohit-allow-internal"
  network = google_compute_network.vpc.name
  project = var.project_id

  priority  = 1000
  direction = "INGRESS"

  allow { protocol = "tcp" }
  allow { protocol = "udp" }
  allow { protocol = "icmp" }

  source_ranges = ["10.0.0.0/24", "10.8.0.0/28"]
}
