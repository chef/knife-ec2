# knife-ec2 change log

Note: this log contains only changes from knife-ec2 release 0.8.0 and later
-- it does not contain the changes from prior releases. To view change history
prior to release 0.8.0, please visit the [source repository](https://github.com/opscode/knife-ec2/commits).

## Latest Release: 0.12.0 (2015-10-1)

* [knife-ec2:#305](https://github.com/chef/knife-ec2/pull/305) Updates to support standard .aws/credentials file
* [knife-ec2 #354](https://github.com/chef/knife-ec2/pull/354) knife-windows 1.0.0 dependency, support for validatorless bootstrap, other Chef 12 bootstrap options
* [knife-ec2 #356](https://github.com/chef/knife-ec2/pull/356) Added --forward-agent option

## Release: 0.11.0 (2015-08-24)
* [knife-ec2:#330](https://github.com/chef/knife-ec2/pull/330) Modification for attribute precedence issue
* [knife-ec2:#293](https://github.com/chef/knife-ec2/pull/293) s3_source: Lazy load fog library
* [knife-ec2:#284](https://github.com/chef/knife-ec2/pull/284) Enable Spot Pricing
* [knife-ec2:#280](https://github.com/chef/knife-ec2/pull/280) Support for EBS volume encryption in knife-ec2 server create options
* [knife-ec2:#273](https://github.com/chef/knife-ec2/pull/273) Remove -s option for data bag secret and subnets
* [knife-ec2:#268](https://github.com/chef/knife-ec2/pull/268) Updated gemspec to use fog v1.25
* [knife-ec2:#265](https://github.com/chef/knife-ec2/pull/265) showing error message for incorrect option input
* [knife-ec2:#261](https://github.com/chef/knife-ec2/pull/261) Remove 'em-winrm' gem dependency
* [KNIFE-464](https://tickets.opscode.com/browse/KNIFE-464) Support EC2 STS, i.e. AWS Federation tokens for authentication

## Release: 0.10.0.rc.1 (2014-10-08)
* [Issue:#237](https://github.com/opscode/knife-ec2/issues/237) Provide a way to the validation key and data bag secret from S3
* [Issue:#243](https://github.com/opscode/knife-ec2/issues/243) Support new AWS CLI configuration file format
* Update `knife-windows` gem dependency to `knife-windows 0.8.rc.0` for improved Windows authentication integration
* Update `fog` gem dependency to `fog 1.23.0`
* Provisioned IOPS support via the `--provisioned-iops` and `--ebs-volume-type` options
* [KNIFE-466](https://tickets.opscode.com/browse/KNIFE-466) Knife ec2 should use gateway from net::ssh config if available
* [KNIFE-422](https://tickets.opscode.com/browse/KNIFE-422) Knife ec2 server create doesn't respect identity file of gateway server from ssh\_config

## Release: 0.8.0 (2014-03-10)
* [KNIFE-458](https://tickets.opscode.com/browse/KNIFE-458) Docs: Increase detail about necessary
  options for VPC instance creation
* [KNIFE-456](https://tickets.opscode.com/browse/KNIFE-456) Documentation for :aws\_credential\_file difficult to read
* [KNIFE-455](https://tickets.opscode.com/browse/KNIFE-455) knife ec2 may try to use private ip for vpc bootstrap even with --associate-public-ip flag
* [KNIFE-453](https://tickets.opscode.com/browse/KNIFE-453) knife-ec2 doesn't handle aws credentials files with windows line endings
* [KNIFE-451](https://tickets.opscode.com/browse/KNIFE-451) Update Fog version to 1.20.0
* [KNIFE-430](https://tickets.opscode.com/browse/KNIFE-430) server creation tunnelling should wait for a valid banner before continuing
* [KNIFE-381](https://tickets.opscode.com/browse/KNIFE-381) Gabriel Rosendorf Add ability to associate public ip with VPC
  instance on creation

## Releases prior to 0.8.0
Please see <https://github.com/opscode/knife-ec2/commits> to view changes in
the form of commits to the source repository for releases before 0.8.0.


