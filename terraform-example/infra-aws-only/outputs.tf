output "aws_instances_external" {
    value = "[ ${aws_instance.weave_head_node.public_ip}, ${join(", ", aws_instance.weave.*.public_ip)} ]"
}

output "aws_instances_internal" {
    value = "[ ${aws_instance.weave_head_node.private_ip}, ${join(", ", aws_instance.weave.*.private_ip)} ]"
}
