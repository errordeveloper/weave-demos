// Please make sure to obtain `account.json` and `client_secrets.json`,
// for more details see:
// 1: https://www.terraform.io/docs/providers/google/index.html
// 2: https://console.developers.google.com/project/<PROJECT_ID>/apiui/credential
provider "google" {
    account_file = "infra/account.json" // you need to obtain this file
    client_secrets_file = "infra/client_secrets.json" // and this one
    project = "stone-album-778" // fill this
    region = "us-central1"
}
