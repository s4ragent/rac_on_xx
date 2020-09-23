locals{ 
        yaml = yamldecode(file("./vars.yml"))
	common_yaml =  yamldecode(file("../common_vars.yml"))
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

resource "google_compute_instance" "development" {
  name         = "development"
  machine_type = "n1-standard-1"
  zone         = "asia-northeast1-c"
  description  = "gcp-2016-advent-calendar"
  tags         = ["development", "mass"]

  disk {
    image = local.yaml.image
  }

  // Local SSD disk
  disk {
    type        = "local-ssd"
    scratch     = true
    auto_delete = true
  }

  network_interface {
    access_config {
      // Ephemeral IP
    }

    subnetwork = "${google_compute_subnetwork.development.name}"
  }

  service_account {
    scopes = ["userinfo-email", "compute-ro", "storage-ro", "bigquery", "monitoring"]
  }

  scheduling {
    on_host_maintenance = "MIGRATE"
    automatic_restart   = true
  }
}
