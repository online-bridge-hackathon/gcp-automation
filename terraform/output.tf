output "ingress_ip" {
  value = google_compute_address.ingress-address
}

output "nat_ip" {
  value = google_compute_address.nat-address
}
