<!---
This file is reset everytime when a new release is done. Contents of this file is for the currently unreleased version.
-->

# knife-ec2 doc changes

Documentation changes are given below for **knife-ec2 version 0.13.1**.

## `knife ec2 server create` subcommand changes

### `--security-group-id` option

The `--security-group-id` option allows user to specify security group id for server. required when using VPC. User can use this opiton multiple times when specifying multiple security groups. e.g. -g sg-e985168d -g sg-e7f06383 -g sg-ec1b7e88.

### `--security-group-ids` option

The security group ids for this server; required when using VPC. Provide values in format --security-group-ids 'X,Y,Z'. [DEPRECATED] This option will be removed in future release. Use the new --security-group-id option. ",