terraform {
  required_version = ">= 0.12.7"
  backend  "gcs" {}
}

provider "google" {
  version     = "~> 2.10"
  project     = var.project_id
  region      = var.region
}

resource "google_compute_instance" "ocr_vm" {
  project = var.project_id
  name = var.vm_name
  zone = var.zone
  machine_type = var.machine_type

  network_interface {
    network = var.network

    access_config {

    }
  }

  tags = ["ocr"]

  boot_disk {
    initialize_params {
      image = "projects/deeplearning-platform-release/global/images/family/pytorch-latest-gpu"
      size = 200
    }
  }

  guest_accelerator = [{
    type = "nvidia-tesla-p100"
    count = 1
  }]

  metadata = {
    install-nvidia-driver = "True"
  }

  scheduling {
    on_host_maintenance = "TERMINATE"
  }
}

resource "google_compute_firewall" "ssh-firewall" {
  project = var.project_id
  name    = "ssh-firewall"
  network = var.network

  allow {
    protocol = "tcp"
    ports    = ["22"]
  }

  source_ranges = ["0.0.0.0/0"]
  target_tags = ["ocr"]
}
