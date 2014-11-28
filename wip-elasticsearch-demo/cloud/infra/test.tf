resource "aws_instance" "weave" {
    count = 3
    instance_type = "m3.xlarge"

    ami = "ami-46e14e31"

    key_name = "terraform"

    user_data = "${file("cloud-config.yaml")}"

    security_groups = ["weave"]
}

resource "aws_security_group" "weave" {
    name = "weave"
    description = "Allow inboud SSH connections"

    ingress {
        from_port = 22
        to_port = 22
        protocol = "tcp"
        cidr_blocks = ["0.0.0.0/0"]
    }
}

resource "google_compute_instance" "weave" {
    count = 3
    machine_type = "n1-standard-1"
    zone = "us-central1-a"

    name = "weave-gce-${count.index}"

    disk {
        image = "coreos-alpha-509-1-0-v20141124"
    }

    network {
        source = "${google_compute_network.weave.name}"
    }

    metadata {
        user-data = "${file("cloud-config.yaml")}"
    }
}

resource "google_compute_network" "weave" {
    name = "default"
    ipv4_range = "10.240.0.0/16"
}

resource "google_compute_firewall" "weave" {
    name = "ports"
    network = "${google_compute_network.weave.name}"

    allow {
        protocol = "icmp"
    }

    allow {
        protocol = "tcp"
        ports = ["22", "6783"]
    }

    allow {
        protocol = "udp"
        ports = ["22", "6783"]
    }

    source_ranges = ["0.0.0.0/0"]
}
