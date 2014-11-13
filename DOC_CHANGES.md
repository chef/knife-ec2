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
configuration enables the EC2 instance to be configured with the specified
provisioned IOPS rate given as an argument to this option. It is only valid if
the EBS volume type is `io1` as specified by the `--ebs-volume-type` option
for this plugin.

## Option `--use-iam-profile` for server create command
This option allows the `knife-ec2 server create` command executing on an EC2 instance to use
IAM role credentials available to the instance as the AWS credentials for
creating new instances. Specify the IAM profile that the instance should use
as an argument to this option.

## Use of secret parameters from S3 for `server create` command
The options below allow some secrets used with the `knife ec2 server create`
command to be specified as URL's. Examples are also given in the README.md.

### Option `--s3-secret`
This option allows the specification of an AWS S3 storage bucket that contains
a data bag secret file -- this option can be used in place of the
`secret_file` option. It takes an S3 URL as an argument (e.g.
`s3://bucket/file`) -- that file should contain encrypted data bag secret file

### Option `--validation-key-url`
This option allows the validation key to be specified as a URL. It takes a URL
as an argument.

## SSH Gateway from SSH Config
Any available SSH Gateway settings in your SSH configuration file are now used
by default. This includes using any SSH keys specified for the target host.
This allows simpler command-line usage of the knife plugin with less of a need
for complex command line invocations.

## Pass separate SSH Gateway key
You can pass an SSH key to be used for authenticating to the SSH Gateway with
the --ssh-gateway-identity option.


   
