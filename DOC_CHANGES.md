<!---
This file is reset everytime when a new release is done. Contents of this file is for the currently unreleased version.
-->

# knife-ec2 doc changes

Documentation changes are given below for **kn9fe-ec2 version 0.13.0**.

## `--aws-config-file` option for all commands

The `--aws-config-file` option allows users to reuse configuration settings from the AWS command line tools so that `knife` can access EC2 resources.

## `knife ec2 server create` subcommand changes

### `--spot-wait-mode` option

The `--spot-wait-mode` option allows knife to respond in different ways when the `server create` subcommand is used to create a spot instance that is not immediately created when the subcommand is executed. Possible options are:

* `wait` -- waits indefinitely for the instance to be created
* `exit` -- exits if the instance is not yet created (it may be bootstrapped via the `knife bootstrap` command at a later time).
* `prompt` (default) -- interactively prompts the user for one of the above options.

### `create-ssl-listener`
The `create-ssl-listener` option is applicable only when creating a Windows instance. When specified, the subcommand will create a `WinRM` listener on the new instance that uses the SSL transport, and will attempt to bootstrap the node using that listener. The default behavior is to use the SSL transport, the `--no-create-ssl-listener` option can be used to override the default and instead use a less secure plaintext listener.

### `network-interfaces`
The `network-interfaces` option allows the user to specify a list of network interfaces in the form `ENI1,ENI2,...` as additional interfaces to attach to the instance when it is created.

### `classic_link_vpc_id`
The `classic_link_vpc_id` option allows the user to specify a VPC that is [ClassicLink](http://docs.aws.amazon.com/AWSEC2/latest/UserGuide/vpc-classiclink.html)-enabled by specifying the VPC's ID as an argument. The created instance will be linked to that VPC.

### `classic-link-vpc-security-group-ids`
The `classic-link-vpc-security-group-ids` option allows the user to specify AWS security groups for the VPC specified with the `classic_link_vpd_id` option.

### `--disable-api-termination`
The `--disable-api-termination` option allows the user to disable the termination of the instance using the Amazon EC2 console, CLI and API. However, this option won't work for `spot instances` as `termination protection` cannot be enabled for `spot instances`.
