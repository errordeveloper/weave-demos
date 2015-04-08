## TODO: Refactor into a module

resource "aws_instance" "weave_head_node" {
    count = 1
    instance_type = "${var.aws_instance_type}"

    ami = "${var.aws_coreos_ami}"

    key_name = "${var.aws_key_name}"

    user_data = "${file("cloud-config.yaml")}"

    security_groups = [ "${aws_security_group.weave.id}" ]
    subnet_id = "${aws_subnet.weave.id}"
    associate_public_ip_address = true

    provisioner "file" {
        source = "genenv-aws-only.sh"
        destination = "/tmp/genenv.sh"
        connection {
            user = "core"
            key_file = "${var.aws_key_path}"
        }
    }

    provisioner "remote-exec" {
        inline = [
            "sudo sh /tmp/genenv.sh ${count.index} '${var.weave_launch_password}'",
            "sudo systemctl start weave",
        ]
        connection {
            user = "core"
            key_file = "${var.aws_key_path}"
        }
    }

    provisioner "local-exec" {
        command = "sh gensshwrapper.sh aws_head '${count.index}' '${var.aws_key_path}' '${self.public_ip}'"
    }
}

resource "aws_instance" "weave" {
    count = "${var.aws_instance_count}"
    instance_type = "${var.aws_instance_type}"

    ami = "${var.aws_coreos_ami}"

    key_name = "${var.aws_key_name}"

    user_data = "${file("cloud-config.yaml")}"

    security_groups = [ "${aws_security_group.weave.id}" ]
    subnet_id = "${aws_subnet.weave.id}"
    associate_public_ip_address = true

    provisioner "file" {
        source = "genenv-aws-only.sh"
        destination = "/tmp/genenv.sh"
        connection {
            user = "core"
            key_file = "${var.aws_key_path}"
        }
    }

    provisioner "remote-exec" {
        inline = [
            "sudo sh /tmp/genenv.sh ${count.index} '${var.weave_launch_password}' ${aws_instance.weave_head_node.private_ip}",
            "sudo systemctl start weave",
        ]
        connection {
            user = "core"
            key_file = "${var.aws_key_path}"
        }
    }

    provisioner "local-exec" {
        command = "sh gensshwrapper.sh aws '${count.index}' '${var.aws_key_path}' '${self.public_ip}'"
    }
}

resource "aws_vpc" "weave" {
    cidr_block = "10.220.0.0/16"
}

resource "aws_internet_gateway" "weave" {
    vpc_id = "${aws_vpc.weave.id}"
}

resource "aws_route_table_association" "weave" {
    subnet_id = "${aws_subnet.weave.id}"
    route_table_id = "${aws_route_table.weave.id}"
}

resource "aws_route_table" "weave" {
    vpc_id = "${aws_vpc.weave.id}"
    route {
        cidr_block = "0.0.0.0/0"
        gateway_id = "${aws_internet_gateway.weave.id}"
    }
}

resource "aws_subnet" "weave" {
    vpc_id = "${aws_vpc.weave.id}"
    cidr_block = "10.220.1.0/24"
    map_public_ip_on_launch = true
}

resource "aws_security_group" "weave" {
    name = "weave"
    description = "SSH access from anywhere"
    vpc_id = "${aws_vpc.weave.id}"

    ingress {
        from_port = 22
        to_port = 22
        protocol = "tcp"
        cidr_blocks = ["0.0.0.0/0"]
    }

    ingress {
        from_port = 6783
        to_port = 6783
        protocol = "tcp"
        self = true
    }

    ingress {
        from_port = 6783
        to_port = 6783
        protocol = "udp"
        self = true
    }
}
