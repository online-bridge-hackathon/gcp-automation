variable "project_id" {

}

variable "cluster_name" {

}

variable "region" {

}

variable "cluster_location" {

}

variable "cluster_node_count" {

}

variable "network" {

}

variable "subnetwork" {

}

variable "master_ipv4_cidr_block" {
  default = "172.16.0.16/28"
}

variable "machine_type" {
  default = "n1-standard-2"
}

variable "version_prefix" {
  description = "Return GKE versions that match the string prefix"
  default     = "1.14."
}
