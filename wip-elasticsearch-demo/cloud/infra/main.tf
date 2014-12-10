resource "aws_security_group" "default" {
    name = "weave"
    description = "Only allow SSH"

    # SSH access from anywhere
    ingress {
        from_port = 22
        to_port = 22
        protocol = "tcp"
        cidr_blocks = ["0.0.0.0/0"]
    }

}

resource "aws_instance" "weave" {
    count = 3
    instance_type = "t2.medium"

    ami = "ami-c6e858b1"

    key_name = "terraform"

    user_data = "${file("cloud-config.yaml")}"

    security_groups = ["${aws_security_group.default.name}"]

    provisioner "file" {
        source = "genenv.sh"
        destination = "/tmp/genenv.sh"
        connection {
            user = "core"
            key_file = "ec2_terraform.eu-west-1.pem"
        }
    }

    provisioner "file" {
        source = "units"
        destination = "/tmp/"
        connection {
            user = "core"
            key_file = "ec2_terraform.eu-west-1.pem"
        }
    }

    provisioner "remote-exec" {
        inline = [
            "sudo mv /tmp/units/*.service /etc/systemd/system/",
            "sudo sh /tmp/genenv.sh aws ${count.index} ${join(" ", google_compute_instance.weave.*.network.0.external_address)}",
            "sudo systemctl start weave",
            "sudo systemctl start elasticsearch spark",
        ]
        connection {
            user = "core"
            key_file = "ec2_terraform.eu-west-1.pem"
        }
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

    provisioner "file" {
        source = "genenv.sh"
        destination = "/tmp/genenv.sh"
        connection {
            user = "core"
            key_file = "google_compute_engine"
        }
    }

    provisioner "file" {
        source = "units"
        destination = "/tmp/"
        connection {
            user = "core"
            key_file = "google_compute_engine"
        }
    }

    provisioner "remote-exec" {
        inline = [
            "sudo mv /tmp/units/*.service /etc/systemd/system/",
            "sudo sh /tmp/genenv.sh gce ${count.index}",
            "sudo systemctl start weave",
            "sudo systemctl start elasticsearch spark",
        ]
        connection {
            user = "core"
            key_file = "google_compute_engine"
        }
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
