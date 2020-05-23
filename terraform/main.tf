terraform {
  required_version = ">= 0.12.7"
  backend  "gcs" {}
}

provider "google" {
  version     = "~> 2.10"
  project     = var.project_id
  region      = var.region
}

data "google_client_config" "current" {
}

data "google_container_engine_versions" "main" {
  project        = var.project_id
  location       = var.cluster_location
  version_prefix = var.version_prefix
}

resource "google_container_cluster" "cluster" {
  project                  = var.project_id
  location                 = var.cluster_location
  name                     = var.cluster_name
  provider                 = google
  remove_default_node_pool = true
  initial_node_count       = 1
  min_master_version       = data.google_container_engine_versions.main.latest_master_version

  network    = var.network
  subnetwork = var.subnetwork

  private_cluster_config {
    enable_private_endpoint = false
    enable_private_nodes    = true
    master_ipv4_cidr_block  = var.master_ipv4_cidr_block
  }

  ip_allocation_policy {
    cluster_ipv4_cidr_block  = "/12"
    services_ipv4_cidr_block = "/18"

  }

  // TODO: For production setup, consider configuring this via variable
  master_authorized_networks_config {
    cidr_blocks {
      cidr_block = "0.0.0.0/0"
    }
  }

  monitoring_service = "none"
  logging_service    = "none"
}

resource "google_container_node_pool" "pools" {
  project     = google_container_cluster.cluster.project
  name        = "${var.cluster_name}-node-pool"
  location    = google_container_cluster.cluster.location
  cluster     = google_container_cluster.cluster.name

  node_count  = var.cluster_node_count

  node_config {
    disk_size_gb    = 25
    disk_type       = "pd-standard"
    labels          = {}
    machine_type    = var.machine_type
    tags            = ["bridge-hackathon"]
    metadata = {
      disable-legacy-endpoints = "true"
    }
    oauth_scopes = [
      "https://www.googleapis.com/auth/devstorage.read_only"
    ]
  }
}

resource "google_compute_firewall" "allow-internal-traffic" {
  name                   = "allow-internal-traffic"
  project                = var.project_id
  network                = var.network
  direction              = "INGRESS"
  source_ranges          = [
    "10.0.0.0/8",
    var.master_ipv4_cidr_block
  ]
  priority               = "100"
  target_tags            = ["bridge-hackathon"]

  allow {
    protocol = "tcp"
  }
}

resource "google_compute_address" "ingress-address" {
  project      = var.project_id
  name         = "${var.cluster_name}-external"
  address_type = "EXTERNAL"
  region       = var.region
}

// Create an external NAT IP
resource "google_compute_address" "nat-address" {
  project = var.project_id
  name    = "${var.cluster_name}-nat-ip"
  region  = var.region
}

// Create a cloud router for use by the Cloud NAT
resource "google_compute_router" "router" {
  project = var.project_id
  name    = "${var.cluster_name}-cloud-router"
  region  = var.region
  network = var.network

  bgp {
    asn = 64514
  }
}

// Create a NAT router so the nodes can reach DockerHub, etc
resource "google_compute_router_nat" "nat" {
  project = var.project_id
  name    = "${var.cluster_name}-cloudnat"
  router  = google_compute_router.router.name
  region  = var.region

  nat_ip_allocate_option             = "MANUAL_ONLY"
  nat_ips                            = [google_compute_address.nat-address.self_link]
  source_subnetwork_ip_ranges_to_nat = "ALL_SUBNETWORKS_ALL_IP_RANGES"
}
