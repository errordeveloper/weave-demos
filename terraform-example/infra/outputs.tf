output "aws_instances" {
    value = "[ ${join(", ", aws_instance.weave.*.public_ip)} ]"
}

output "gce_instances" {
    value = "[ ${join(", ", google_compute_instance.weave.*.network.0.external_address)} ]"
}


# Here is how one can out list of ssh commands...
# "\n${format("\n%s -i %s core@", var.ssh_command_hint, var.aws_key_path)} ${join(format("\n%s -i %s core@", var.ssh_command_hint, var.aws_key_path), google_compute_instance.weave.*.network.0.external_address)}"
