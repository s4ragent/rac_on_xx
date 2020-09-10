locals{ 
        yaml = yamldecode(file("./vars.yml"))
}

provider "google" {
	project = local.yaml.project
	region  = local.yaml.region
}
  
resource "google_compute_network" "racnetwork" {
  name = "racnetwork"
}
resource "google_compute_subnetwork" "racsubnetwork" {
  name          = "racsubnetwork"
  ip_cidr_range = local.yaml.ip_cidr_range
  network       = "${google_compute_network.racnetwork.name}"
  description   = "racsubnetwork"
  region        = local.yaml.region
}
