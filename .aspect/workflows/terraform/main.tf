terraform {
  required_version = "~> 1.5.0"

  backend "gcs" {
    bucket = "aw-deployment-terraform-state-bazel-lib"
    prefix = "terraform/state"
  }
}

provider "google" {
  project = "aw-deployment-bazel-lib"
  region  = "us-west2"
}
