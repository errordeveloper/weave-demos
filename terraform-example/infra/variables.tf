variable "weave_launch_password" {
    description = "Set salt (NaCL) passphrase to encrypt weave network"
}

variable "aws_access_key" {
    description = "Your AWS API access key"
    default = ""
}

variable "aws_secret_key" {
    description = "Your AWS API secret key"
    default = ""
}

variable "aws_region" {
    description = "Region to run AWS instances in"
    default = "eu-west-1"
}

variable "aws_key_name" {
    description = "Name of the SSH key pair in the chosen AWS region"
    default = "terraform"
}

variable "aws_key_path" {
    description = "Path to private SSH key for the chosen AWS region"
    default = "~/.ssh/ec2_terraform.eu-west-1.pem"
}

variable "aws_coreos_ami" {
    description = "Name of CoreOS AMI in the chosen AWS region for instances to use"
    default = "ami-5b911f2c"
}

variable "aws_instance_type" {
    description = "Type of instance ot use in AWS"
    default = "m3.large"
}

variable "gce_account_file" {
    description = "Path to your GCE account credentials file"
    default = "account.json"
}

variable "gce_client_secrets_file" {
    description = "Path to your GCE client secrets file"
    default = "client_secrets.json"
}

variable "gce_project_name" {
    description = "Name of your existing GCE project"
    default = ""
}

variable "gce_region" {
    description = "Region to run GCE instances in"
    default = "us-central1"
}

variable "gce_zone" {
    description = "Zone to run GCE instances in"
    default = "us-central1-a"
}

variable "gce_key_path" {
    description = "Path to private SSH key for the GCE instances"
    default = "~/.ssh/google_compute_engine"
}

variable "gce_coreos_disk_image" {
    description = "Name of CoreOS Root disk image for the GCE instances to use"
    default = "coreos-stable-557-2-0-v20150210"
}

variable "gce_machine_type" {
    description = "Type of instance ot use in GCE"
    default = "n1-standard-1"
}

variable "ssh_command_hint" {
    description = "SSH command with arguments for helpful output"
    default = "ssh -o Compression=yes -o LogLevel=FATAL -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null -o IdentitiesOnly=yes"
}
