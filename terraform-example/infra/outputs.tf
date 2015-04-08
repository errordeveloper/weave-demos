output "aws_instances_external" {
    value = "[ ${join(", ", aws_instance.weave.*.public_ip)} ]"
}

output "gce_instances_external" {
    value = "[ ${join(", ", google_compute_instance.weave.*.network.0.external_address)} ]"
}

output "aws_instances_internal" {
    value = "[ ${join(", ", aws_instance.weave.*.private_ip)} ]"
}

output "gce_instances_internal" {
    value = "[ ${join(", ", google_compute_instance.weave.*.network.0.internal_address)} ]"
}
