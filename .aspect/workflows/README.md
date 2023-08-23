# Aspect Workflows demonstration deployment

This deployment of [Aspect Workflows](https://www.aspect.build/workflows) is configured to run on GCP + CircleCI.

You can see this Aspect Workflows demonstration deployment live at https://app.circleci.com/pipelines/github/aspect-build/bazel-lib.

The three components of the configuration are,

1. Aspect Workflows terraform module
1. Aspect Workflows configuration yaml
1. CircleCI pipeline configuration

## Aspect Workflows terraform module

This is found under the [.aspect/workflows/terraform](./terraform) directory.

## Aspect Workflows configuration yaml

This is the [config.yaml](./config.yaml) file in this directory.

## CircleCI pipeline configuration

This is the [.circleci/config.yml](../../.circleci/config.yml) file.
