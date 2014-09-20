<!---
This file is reset everytime when a new release is done. Contents of this file is for the currently unreleased version.
-->

# knife-ec2 doc changes

Documentation changes are given below for **knife-ec2 version 0.10.0**.

## Provisioned IOPS support for `server create` command

Options are now available in the `knife ec2 server create` subcommand to
specify provisioned IOPS for the created instance.

### Option `--ebs-volume-type`

This command line option and associated plugin configuration `:ebs_volume_type` allow you to specify an EBS volume of type `standard` or `io1` as a `string` parameter to this option. The former is the default, the latter will allow the specification of a provisioned IOPS rate through the `--provisioned-iops` option.

### Option `--provisioned-iops`
This command line option and the associated `:ebs_provisioned_iops` plugin
confugration enables the EC2 instance to be configured with the specified
provisioned IOPS rate given as an argument to this option. It is only valid if
the EBS volume type is `io1` as specified by the `--ebs-volume-type` option
for this plugin.

## SSH Gateway from SSH Config
Any available SSH Gateway settings in your SSH configuration file are now used
by default. This includes using any SSH keys specified for the target host.
This allows simpler command-line usage of the knife plugin with less of a need
for complex command line invocations.

## Pass seperate SSH Gateway key
You can pass an SSH key to be used for authenticating to the SSH Gateway with
the --ssh-gateway-identity option.


   
