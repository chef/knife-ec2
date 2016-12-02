<!---
This file is reset everytime when a new release is done. Contents of this file is for the currently unreleased version.
-->

# knife-ec2 doc changes

Documentation changes are given below for **knife-ec2 version 0.14.0**.

## `knife ec2 server create` subcommand changes

### `--security-group-id` option

The `--security-group-id` option allows the user to specify the security group id for server and is required when using VPC. Multiple security groups may be specified by using this option multiple times, e.g. `-g sg-e985168d -g sg-e7f06383 -g sg-ec1b7e88`.

### `--security-group-ids` option

The previous option for specifying security groups, `--security-group-ids` (plural), is deprecated in favor of the `--security-group-id` option which mimics the more standard behavior for supplying multiple arguments across the ecosystem. This option will be removed in future release.
