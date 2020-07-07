variable "project_id" {
  description = "project for main"
  default = "inspired-bebop-278005"
}

variable "region" {
  description = "region"
}
variable "zone" {
  description = "zone"
}
provider "google" {
  project = var.project_id
  region  = var.region
  zone    = var.zone
}

variable "gke_username" {
  default     = ""
  description = "gke username"
}

variable "gke_password" {
  default     = ""
  description = "gke password"
}
variable "http_load_balancing_disabled" {
  type    = string
  default = "false"
}
variable "gke_num_nodes" {
  default     = 3
  description = "number of gke nodes"
}

data "google_client_config" "default" {
}

data "google_container_cluster" "my_cluster" {
  name = "my-cluster"
  zone = "us-central1-a"
}

provider "kubernetes" {
  load_config_file = false

  host  = "https://${data.google_container_cluster.my_cluster.endpoint}"
  token = data.google_client_config.default.access_token
  cluster_ca_certificate = base64decode(
    data.google_container_cluster.my_cluster.master_auth[0].cluster_ca_certificate,
  )
}

# GKE cluster
resource "google_container_cluster" "primary" {
  name     = "${var.project_id}-gke"
  location = var.zone
   #http_load_balancing = true
  remove_default_node_pool = true
  initial_node_count       = 1

  network    = "${var.project_id}-vpc"
##  subnetwork = google_compute_subnetwork.subnet.name
  subnetwork = "${var.project_id}-subnet"
  master_auth {
    username = var.gke_username
    password = var.gke_password

    client_certificate_config {
      issue_client_certificate = false
    }
    
  }

}
 
# Separately Managed Node Pool
resource "google_container_node_pool" "primary_nodes" {
  name       = "${google_container_cluster.primary.name}-node-pool"
  location   = var.zone
  cluster    = google_container_cluster.primary.name
  node_count = var.gke_num_nodes
  autoscaling {
      min_node_count = 1
      max_node_count = 3
    }
  node_config {
    oauth_scopes = [
      "https://www.googleapis.com/auth/logging.write",
      "https://www.googleapis.com/auth/monitoring",
    ]
    
    labels = {
      env = var.project_id
    }

    # preemptible  = true
    machine_type = "n1-standard-2"
    image_type   = "ubuntu_containerd"
    tags         = ["gke-node", "${var.project_id}-gke"]
    metadata = {
      disable-legacy-endpoints = "true"
    }
  }
}

output "kubernetes_cluster_name" {
  value       = google_container_cluster.primary.name
  description = "GKE Cluster Name"
}



