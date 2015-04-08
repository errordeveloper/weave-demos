output "aws_instances" {
    value = "[ ${join(", ", aws_instance.weave.*.public_ip)} ]"
}

output "gce_instances" {
    value = "[ ${join(", ", google_compute_instance.weave.*.network.0.external_address)} ]"
}
