locals{ 
        yaml = yamldecode(file("./vars.yml"))
}

provider "google" {
	project = local.yaml.project
	region  = local.yaml.region
  }
  
  resource "google_compute_instance" "apps-gcp-terraform" {
	name         = "apps-gcp-terraform"
	machine_type = "g1-small"
	zone         = "asia-northeast1-a"
  
	boot_disk {
	  initialize_params {
		size  = 10
		type  = "pd-standard"
		image = "debian-cloud/debian-9"
	  }
	}
  
	network_interface {
	  network       = "default"
	  access_config = {}
	}
  
	service_account = {
	  scopes = ["logging-write", "monitoring-write"]
	}
  }
