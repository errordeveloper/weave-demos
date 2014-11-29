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
    instance_type = "m3.xlarge"

    ami = "ami-c6e858b1"

    key_name = "terraform"

    # instead of using boostrap_env_file_on_aws.sh
    # we can concat the vars inline here, but that
    # requires some refactoring of cloud-config.yaml
    user_data = "${file("cloud-config.yaml")}"

    security_groups = ["${aws_security_group.default.name}"]

    provisioner "file" {
        source = "boostrap_env_file_on_aws.sh"
        destination = "/tmp/boostrap_env_file_on_aws.sh"
        connection {
            user = "core"
            key_file = "ec2_terraform.eu-west-1.pem"
        }
    }
    provisioner "remote-exec" {
        inline = [
          "sudo sh /tmp/boostrap_env_file_on_aws.sh ${count.index} ${join(" ", google_compute_instance.weave.*.network.0.external_address)}",
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
