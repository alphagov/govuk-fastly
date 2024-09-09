# govuk-fastly

This repository contains Terraform code to deploy GOV.UK CDN services to Fastly.
The VCL templates in this repository depend on secrets set in [govuk-fastly-secrets](https://github.com/alphagov/govuk-fastly-secrets) to render correctly.

## Quick Start

1. Ensure you have [Terraform Cloud access](#getting-terraform-cloud-access)
1. Make changes to the templates or other configuration
1. Open a PR and wait for Terraform Cloud to run a plan against your changes
  * Terraform Cloud's VCL diff display is pretty poor. To see a better diff, check the `fastly-vcl-diff` post-plan task on your run page
1. If you are happy with the plan, merge your PR
1. Watch the apply on the Terraform Cloud UI

## Running plans without opening a PR

1. Ensure you have terraform installed (tfenv is preferable)
1. Log in to your Terraform Cloud account with `terraform login`
1. `cd` to the service module in which you wish to make changes
1. Run `terraform init` and pick an environment to run the plan in
1. Run `terraform plan` to run plans with your local copy of the config

## File Structure

* `shared/` - contains common files that are used by multiple services
* `www/ab_tests.yaml` - list of AB test variants
* `dictionaries.yaml` - non-secret Fastly dictionaries (e.g. AB test expiry times)

Each other directory in the root of this repo is a Fastly service.

## Getting Terraform Cloud access

Terraform Cloud uses Google SSO for login. To create your account, go to the [SSO login page](https://app.terraform.io/sso/sign-in) and use the organisation name `govuk`. Your permissions are determined by which Google groups you are a member of.

## Caveats

* If you update secrets in the [govuk-fastly-secrets](https://github.com/alphagov/govuk-fastly-secrets) repository, you may need to also run an apply on this repository after for your changes to take effect
* All environments for a given service share a common VCL template. If you need to make changes to the VCL, you may want to wrap your changes in an `if` statement, or specify `vcl_template_file` in `govuk-fastly-secrets` to temporarily use a different template file for a given environment.
