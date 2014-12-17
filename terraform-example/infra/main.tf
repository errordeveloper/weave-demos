// Declare and provision 3 GCE instances
resource "google_compute_instance" "weave" {
    count = 3
    // By default (see variables.tf), these are going to be of type 'n1-standard-1' in zone 'us-central1-a'.
    machine_type = "${var.gce_machine_type}"
    zone = "${var.gce_zone}"

    // Ensure clear host naming scheme, which results in functional native DNS within GCE
    name = "weave-gce-${count.index}" // => `weave-gce-{0,1,2}`

    // Attach an alpha image of CoreOS as the primary disk
    disk {
        image = "${var.gce_coreos_disk_image}"
    }

    // Attach to a network with some custom firewall rules (details further down)
    network {
        source = "${google_compute_network.weave.name}"
    }

    // Provisioning

    // 1. Cloud Config phase writes systemd unit definitions and only starts two host-independent units —
    // `pre-fetch-container-images.service` and `install-weave.service`
    metadata {
        user-data = "${file("cloud-config.yaml")}"
    }

    // 2. Upload shell script that generates host-specific environment file to be used by `weave.service`
    provisioner "file" {
        source = "genenv.sh"
        destination = "/tmp/genenv.sh"
        connection {
            user = "core"
            key_file = "${var.gce_key_path}"
        }
    }

    // 3. Run the `genenv.sh` script
    // 4. Start `weave.service`
    provisioner "remote-exec" {
        inline = [
            "sudo sh /tmp/genenv.sh gce ${count.index} '${var.weave_launch_password}'",
            "sudo systemctl start weave",
        ]
        connection {
            user = "core"
            key_file = "${var.gce_key_path}"
        }
    }
}

// Custom GCE network declaration, so we can set firewall rules below
resource "google_compute_network" "weave" {
    name = "default"
    ipv4_range = "10.240.0.0/16"
}

// Firewall rules for the network (allow inbound ssh and weave connections)
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

// Declare and provision 3 AWS instances
resource "aws_instance" "weave" {
    count = 3
    // By default (see variables.tf), these are going to be of type 'm3.large' in region 'eu-west-1'.
    count = 3
    instance_type = "${var.aws_instance_type}"

    // Use an alpha image of CoreOS
    ami = "${var.aws_coreos_ami}"

    // Set the SSH key name to use (default: "terrraform")
    key_name = "${var.aws_key_name}"

    // Provisioning (mostly identical to the GCE counter-part)

    user_data = "${file("cloud-config.yaml")}"

    security_groups = ["${aws_security_group.default.name}"]

    provisioner "file" {
        source = "genenv.sh"
        destination = "/tmp/genenv.sh"
        connection {
            user = "core"
            key_file = "${var.aws_key_path}"
        }
    }

    // The only difference here is what arguments are passed to `genenv.sh`
    provisioner "remote-exec" {
        inline = [
            "sudo sh /tmp/genenv.sh aws ${count.index} '${var.weave_launch_password}' ${join(" ", google_compute_instance.weave.*.network.0.external_address)}",
            "sudo systemctl start weave",
        ]
        connection {
            user = "core"
            key_file = "${var.aws_key_path}"
        }
    }
}

// Firewall rules for our security group only need to allow inbound ssh connections
resource "aws_security_group" "default" {
    name = "weave"
    description = "SSH access from anywhere"

    ingress {
        from_port = 22
        to_port = 22
        protocol = "tcp"
        cidr_blocks = ["0.0.0.0/0"]
    }
}
