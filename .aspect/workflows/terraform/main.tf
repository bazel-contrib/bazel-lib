terraform {
  required_version = "~> 1.4.0"

  backend "gcs" {
    bucket = "aw-deployment-terraform-state-bazel-lib"
    prefix = "terraform/state"
  }
}

locals {
  # Project & region of the Workflows deployment. Alternately, you may configure a global `provider
  # "google"` with the desired project & region and the Workflows module will default to that.
  project = "aw-deployment-bazel-lib"
  region  = "us-west2"
}
