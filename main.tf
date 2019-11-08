resource "null_resource" "dependency_getter" {
  provisioner "local-exec" {
    command = "echo ${length(var.dependencies)}"
  }
}

resource "random_id" "bucketid" {
  byte_length = 4
  prefix      = "moduleB-"
}

resource "google_storage_bucket" "bucketB" {
  name     = random_id.bucketid.hex
}

resource "google_compute_instance" "bastion_host" {
  project      = var.project
  name         = var.instance_name
  machine_type = var.machine_type
  zone         = var.zone
  depends_on    = ["null_resource.dependency_getter"]

  tags = [var.tag]

  boot_disk {
    initialize_params {
      image = var.source_image
    }
  }

  network_interface {
    subnetwork = var.subnetwork

    // If var.static_ip is set use that IP, otherwise this will generate an ephemeral IP
    access_config {
      nat_ip = var.static_ip
    }
  }

  metadata_startup_script = var.startup_script

  metadata = {
    enable-oslogin = "TRUE"
  }
}

resource "null_resource" "dependency_setter" {
  depends_on = [
    "google_storage_bucket.bucketB",
  ]
}

variable "dependencies" {
  type    = "list"
  default = []
}

output "depended_on" {
  value = "${null_resource.dependency_setter.id}"
}
