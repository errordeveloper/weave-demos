provider "aws" {
    access_key = "${var.aws_access_key}"
    secret_key = "${var.aws_secret_key}"
    region = "${var.aws_region}"
}

provider "google" {
    account_file = "${var.gce_account_file}"
    # client_secrets_file = "${var.gce_client_secrets_file}" # not needed since 0.4.0
    project = "${var.gce_project_name}"
    region = "${var.gce_region}"
}
