<!---
This file is reset everytime when a new release is done. Contents of this file is for the currently unreleased version.
-->

# knife-ec2 doc changes

Documentation changes are given below for **knife-ec2 version 0.18.0**.

## `knife ec2 server create` subcommand changes

### `--aws-tag` option

The `--aws-tag` option is used for tagging the EC2 instances in AWS as `key=value` pair. Use this option like e.g. `--aws-tag <key1=value1>`. Multiple tags can be added by specifying the option multiple times.

### `--chef-tag` option

The `--chef-tag` option is used for tagging the EC2 instances on the Chef server. Use this option like e.g. `--chef-tag <myTag>`. Multiple tags can be added by specifying the option multiple times.
