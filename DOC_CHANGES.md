<!---
This file is reset everytime when a new release is done. Contents of this file is for the currently unreleased version.
-->

# knife-ec2 doc changes

Documentation changes are given below for **knife-ec2 version 0.17.0**.

## `knife ec2 server create` subcommand changes

### `--instance-initiated-shutdown-behavior` option

The `--instance-initiated-shutdown-behavior` option indicates whether an instance stops or terminates when you initiate shutdown from the instance. Possible values are 'stop' and 'terminate', default is 'stop'.

### `--primary-eni` option

Specify a pre-existing ENI for primary interface when building the instance.
