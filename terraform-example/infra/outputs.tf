#output "aws_instances" {
#    value = "AWS instances:\n - ${join("\n - ", aws_instance.weave.*.public_ip)}"
#}

#output "gce_instances" {
#    value = "GCE instances:\n - ${join("\n - ", google_compute_instance.weave.*.network.0.external_address)}"
#}
