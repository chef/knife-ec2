# knife-ec2 change log

Note: this log contains only changes from knife-ec2 release 0.8.0 and later
-- it does not contain the changes from prior releases. To view change history
prior to release 0.8.0, please visit the [source repository](https://github.com/chef/knife-ec2/commits).

## Latest Release 0.14.0 (2016-12-02)
* `knife-ec2` requires `chef-client 12.14` or newer.
* [knife-ec2:#442](https://github.com/chef/knife-ec2/pull/442) Added support to show flavor list in json format.
* [knife-ec2:#439](https://github.com/chef/knife-ec2/pull/439) Allow to accept multiple security group ids using --security-group-id option multiple times and added deprecated message for comma seprated --security-group-ids option.

## Release 0.13.0 (2016-08-05)
* [knife-ec2:#438](https://github.com/chef/knife-ec2/pull/438) Specs for ec2 server list
* [knife-ec2:#437](https://github.com/chef/knife-ec2/pull/437) Fix --aws-credential-file issues
* [knife-ec2:#436](https://github.com/chef/knife-ec2/pull/436) basic is not a valid setting for winrm_ssl_verify_mode
* [knife-ec2:#435](https://github.com/chef/knife-ec2/pull/435) Fix for Winrm Authentication Failure issue during bootstrap
* [knife-ec2:#434](https://github.com/chef/knife-ec2/pull/434) Removed ruby2.0.0 from travis
* [knife-ec2:#431](https://github.com/chef/knife-ec2/pull/431) Pinned rack and ffi-yajl gem to older versions.
* [knife-ec2:#430](https://github.com/chef/knife-ec2/pull/430) Fixing --aws-config-file issues
* [knife-ec2:#429](https://github.com/chef/knife-ec2/pull/429) Added validation when spot-wait-mode option is given by user on CLI and spot-price option is not given.
* [knife-ec2:#428](https://github.com/chef/knife-ec2/pull/428) Fix for s3 secret not getting copied on target vm
* [knife-ec2:#427](https://github.com/chef/knife-ec2/pull/427) Addedd disable_api_termination option along with RSpecs.
* [knife-ec2:#416](https://github.com/chef/knife-ec2/pull/416) Modified help for option --security-group-ids
* [knife-ec2:#409](https://github.com/chef/knife-ec2/pull/409) Passing encrypted\_data\_bag\_secret and encrypted\_databag\_secret\_file
* [knife-ec2:#405](https://github.com/chef/knife-ec2/pull/405) Updated README file - added description of aws\_config\_file option
* [knife-ec2:#399](https://github.com/chef/knife-ec2/pull/399) Adding support for aws-config-file
* [knife-ec2:#400](https://github.com/chef/knife-ec2/pull/400) Added --json-for-attributes-file
* [knife-ec2:#393](https://github.com/chef/knife-ec2/pull/393) Please also read aws\_session\_token from credentials file - [Richard Morrisey](https://github.com/datascope)
* [knife-ec2:#395](https://github.com/chef/knife-ec2/pull/395) Fix security groups for spot requests in a VPC and make user input optional - [Mikhail Bautin](https://github.com/mbautin)
* [knife-ec2:#322](https://github.com/chef/knife-ec2/pull/322) Implement support for ClassicLink [Quention de Metz](https://github.com/quentindemetz)
* [knife-ec2:#391](https://github.com/chef/knife-ec2/pull/391) adding missing m4,d2,t2,and g2 ebs encryption flavors - [Mario Harvey](https://github.com/badmadrad)
* [knife-ec2:#390](https://github.com/chef/knife-ec2/pull/390) Modified create\_ssl\_listener option as per Mixlib-CLI.
* [knife-ec2:#375](https://github.com/chef/knife-ec2/pull/375) Attach network interfaces before bootstrap - [Eric Herot](https://github.com/eherot)
* [knife-ec2:#389](https://github.com/chef/knife-ec2/pull/389) --server-connect-attribute cleanup
* [knife-ec2:#388](https://github.com/chef/knife-ec2/pull/388) Updated Readme for --server-connect-attribute option
* [knife-ec2:#384](https://github.com/chef/knife-ec2/pull/384) server list in json format
* [knife-ec2:#378](https://github.com/chef/knife-ec2/pull/378) Readme improvements
* [knife-ec2:#376](https://github.com/chef/knife-ec2/pull/376) Remove instance colors
* [knife-ec2:#377](https://github.com/chef/knife-ec2/pull/377) Require fog-aws vs. fog
* [knife-ec2:#368](https://github.com/chef/knife-ec2/pull/368) Handle Errno::ENOTCONN when testing for sshd access - [Eugene Bolshakov](https://github.com/eugenebolshakov)
* [knife-ec2:#373](https://github.com/chef/knife-ec2/pull/373) Update contributing docs
* [knife-ec2:#374](https://github.com/chef/knife-ec2/pull/374) Avoid sending nil runlist to Chef::Knife::Boostrap
* [knife-ec2:#372](https://github.com/chef/knife-ec2/pull/372) Cache gems in travis, update links and opscode -> chef
* [knife-ec2:#371](https://github.com/chef/knife-ec2/pull/371) fix typo in readme - [Kyle West](https://github.com/kylewest)
* [knife-ec2:#363](https://github.com/chef/knife-ec2/pull/363) Add ssl config user data for ssl transport, if required append to user\_data script specified by user.
* [knife-ec2:#319](https://github.com/chef/knife-ec2/pull/319) Pointing docs at itself. This is better then the non-existent chef.io docs.

## Release: 0.12.0 (2015-10-1)
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
* [Issue:#237](https://github.com/chef/knife-ec2/issues/237) Provide a way to the validation key and data bag secret from S3
* [Issue:#243](https://github.com/chef/knife-ec2/issues/243) Support new AWS CLI configuration file format
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
Please see <https://github.com/chef/knife-ec2/commits> to view changes in
the form of commits to the source repository for releases before 0.8.0.


