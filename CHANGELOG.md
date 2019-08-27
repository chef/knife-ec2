# knife-ec2 change log

Note: this log contains only changes from knife-ec2 release 0.8.0 and later
-- it does not contain the changes from prior releases. To view change history
prior to release 0.8.0, please visit the [source repository](https://github.com/chef/knife-ec2/commits).

<!-- latest_release -->
<!-- latest_release -->

<!-- release_rollup -->
<!-- release_rollup -->

<!-- latest_stable_release -->
## [v1.0.14](https://github.com/chef/knife-ec2/tree/v1.0.14) (2019-08-27)

#### Merged Pull Requests
- Color code fixes in json format output of knife ec2 server list [#606](https://github.com/chef/knife-ec2/pull/606) ([dheerajd-msys](https://github.com/dheerajd-msys))
- Allow instances to be provisioned with source/dest checks disabled [#605](https://github.com/chef/knife-ec2/pull/605) ([kapilchouhan99](https://github.com/kapilchouhan99))
<!-- latest_stable_release -->

## [v1.0.12](https://github.com/chef/knife-ec2/tree/v1.0.12) (2019-08-12)

#### Merged Pull Requests
- Fixes for multiple issuess with network interfaces  [#602](https://github.com/chef/knife-ec2/pull/602) ([vsingh-msys](https://github.com/vsingh-msys))

## [v1.0.11](https://github.com/chef/knife-ec2/tree/v1.0.11) (2019-08-08)

#### Merged Pull Requests
- Add --cpu-credits option for launching T2/T3 instances as unlimited [#603](https://github.com/chef/knife-ec2/pull/603) ([dheerajd-msys](https://github.com/dheerajd-msys))
- Update README for OSS Best Practices [#604](https://github.com/chef/knife-ec2/pull/604) ([dheerajd-msys](https://github.com/dheerajd-msys))

## [v1.0.9](https://github.com/chef/knife-ec2/tree/v1.0.9) (2019-07-29)

#### Merged Pull Requests
- Attach emphemeral disks with using --emphemeral flag &amp; avoid tagging error [#600](https://github.com/chef/knife-ec2/pull/600) ([dheerajd-msys](https://github.com/dheerajd-msys))

## [v1.0.8](https://github.com/chef/knife-ec2/tree/v1.0.8) (2019-07-11)

#### Merged Pull Requests
- Remove deprecated options &amp; set default value for ec2 ami list owner option [#586](https://github.com/chef/knife-ec2/pull/586) ([vsingh-msys](https://github.com/vsingh-msys))

## [v1.0.7](https://github.com/chef/knife-ec2/tree/v1.0.7) (2019-07-08)

#### Merged Pull Requests
- update readme with user data [#588](https://github.com/chef/knife-ec2/pull/588) ([dheerajd-msys](https://github.com/dheerajd-msys))
- Update copyrights to 2019 [#594](https://github.com/chef/knife-ec2/pull/594) ([tas50](https://github.com/tas50))
- Update the readme to not mention DK or the deprecated knife command [#595](https://github.com/chef/knife-ec2/pull/595) ([tas50](https://github.com/tas50))
- Add a buildkite PR verification pipeline [#597](https://github.com/chef/knife-ec2/pull/597) ([tas50](https://github.com/tas50))
- Cutover to Buildkite for all PR testing [#598](https://github.com/chef/knife-ec2/pull/598) ([tas50](https://github.com/tas50))
- Add connection debug information [#596](https://github.com/chef/knife-ec2/pull/596) ([tas50](https://github.com/tas50))

## [v1.0.1](https://github.com/chef/knife-ec2/tree/v1.0.1) (2019-07-08)

#### Merged Pull Requests
- Update codeowners, test on latest ruby releases + more misc [#563](https://github.com/chef/knife-ec2/pull/563) ([tas50](https://github.com/tas50))
- Prep knife-windows v1.0.x [#578](https://github.com/chef/knife-ec2/pull/578) ([btm](https://github.com/btm))
- Convert to aws-sdk and add new commands #546 [#587](https://github.com/chef/knife-ec2/pull/587) ([vsingh-msys](https://github.com/vsingh-msys))

## [v0.19.16](https://github.com/chef/knife-ec2/tree/v0.19.16) (2018-12-11)

#### Merged Pull Requests
- Don&#39;t ship the spec files in the gem [#562](https://github.com/chef/knife-ec2/pull/562) ([tas50](https://github.com/tas50))

## [v0.19.15](https://github.com/chef/knife-ec2/tree/v0.19.15) (2018-12-03)

#### Merged Pull Requests
- Only ship the necessary libraries in the gem [#559](https://github.com/chef/knife-ec2/pull/559) ([tas50](https://github.com/tas50))
- Do not print out a literal \n when deleting servers from ec2 [#558](https://github.com/chef/knife-ec2/pull/558) ([muz](https://github.com/muz))
- Updated descriptions to mention config.rb [#555](https://github.com/chef/knife-ec2/pull/555) ([Vasu1105](https://github.com/Vasu1105))

## [v0.19.12](https://github.com/chef/knife-ec2/tree/v0.19.12) (2018-11-28)

#### Merged Pull Requests
- Misc cleanup to sync with other gems [#552](https://github.com/chef/knife-ec2/pull/552) ([tas50](https://github.com/tas50))
- Pass bootstrap template in common config [#560](https://github.com/chef/knife-ec2/pull/560) ([scotthain](https://github.com/scotthain))

## [v0.19.10](https://github.com/chef/knife-ec2/tree/v0.19.10) (2018-08-06)

#### Merged Pull Requests
- Drop Ruby 2.2 + Add Chefstyle + align testing with other projects [#530](https://github.com/chef/knife-ec2/pull/530) ([tas50](https://github.com/tas50))
- Bump copyrights &amp; minor readme updates [#532](https://github.com/chef/knife-ec2/pull/532) ([tas50](https://github.com/tas50))
- Move contributing docs out of the repo [#535](https://github.com/chef/knife-ec2/pull/535) ([tas50](https://github.com/tas50))
- Add codeowners and PR template files [#533](https://github.com/chef/knife-ec2/pull/533) ([tas50](https://github.com/tas50))
- Update installation instructions in the readme to push ChefDK [#537](https://github.com/chef/knife-ec2/pull/537) ([tas50](https://github.com/tas50))
- Rewrite the credentials section of the readme with new recommendations [#538](https://github.com/chef/knife-ec2/pull/538) ([tas50](https://github.com/tas50))
- Fix knife ami list --group flag description [#539](https://github.com/chef/knife-ec2/pull/539) ([tas50](https://github.com/tas50))
- Clarify which AWS CLI tools we&#39;re talking about [#540](https://github.com/chef/knife-ec2/pull/540) ([tas50](https://github.com/tas50))
- Lazy load deps and avoid double loading [#544](https://github.com/chef/knife-ec2/pull/544) ([tas50](https://github.com/tas50))
- Improve the AMI missing error and improve the readme example [#543](https://github.com/chef/knife-ec2/pull/543) ([tas50](https://github.com/tas50))
- Provide a unique console color for us-east-1f availability zone [#541](https://github.com/chef/knife-ec2/pull/541) ([tas50](https://github.com/tas50))
- Removed deprecated options distro and template_file flags in server create command [#542](https://github.com/chef/knife-ec2/pull/542) ([tas50](https://github.com/tas50))
- Remove readline dep which we&#39;re not using [#547](https://github.com/chef/knife-ec2/pull/547) ([tas50](https://github.com/tas50))
- Remove mime-types dependency [#550](https://github.com/chef/knife-ec2/pull/550) ([tas50](https://github.com/tas50))
- Remove executables from gemspec and cleanup test files [#549](https://github.com/chef/knife-ec2/pull/549) ([tas50](https://github.com/tas50))
- If no keys specified on CLI/config use an AWS credential file if present [#548](https://github.com/chef/knife-ec2/pull/548) ([tas50](https://github.com/tas50))

## [v0.18.2](https://github.com/chef/knife-ec2/tree/v0.18.2) (2018-07-06)

#### Merged Pull Requests
- [MSYS-824] fix breaking tag changes &amp; deprecation warning [#527](https://github.com/chef/knife-ec2/pull/527) ([dheerajd-msys](https://github.com/dheerajd-msys))
- MSYS-798 - Fixes for windows administrator password [#524](https://github.com/chef/knife-ec2/pull/524) ([dheerajd-msys](https://github.com/dheerajd-msys))



## Latest Release 0.18.0 (2018-04-05)
* [knife-ec2:#520](https://github.com/chef/knife-ec2/pull/520) Options `--aws-tag` and `--chef-tag` are added for tagging EC2 instance in AWS and Chef separately.

## Release 0.17.0 (2018-02-07)
* [knife-ec2:#515](https://github.com/chef/knife-ec2/pull/515) Allow re-use of existing ENI for primary interface.
* [knife-ec2:#514](https://github.com/chef/knife-ec2/pull/514) Add `--instance-initiated-shutdown-behavior` option.
* [knife-ec2:#513](https://github.com/chef/knife-ec2/pull/513) require `rb-readline` to avoid ruby 2.4 warnings about `Fixnum`.

## Release 0.16.0 (2017-11-07)
* [knife-ec2:#503](https://github.com/chef/knife-ec2/pull/503) Update list of instance_types that support ebs-encryption.
* [knife-ec2:#496](https://github.com/chef/knife-ec2/pull/496) Change Winrm cert to 10 year expiry.
* [knife-ec2:#492](https://github.com/chef/knife-ec2/pull/492) Added support to tag node details to chef.
* [knife-ec2:#490](https://github.com/chef/knife-ec2/pull/490) Improper alignment of EC2 flavor list.
* [knife-ec2:#489](https://github.com/chef/knife-ec2/pull/489) Added support to handle long passwords in windows.
* [knife-ec2:#488](https://github.com/chef/knife-ec2/pull/488) Added support to tag EBS volumes on node creation.
* [knife-ec2:#487](https://github.com/chef/knife-ec2/pull/487) Added new column description in EC2 AMIs list.

## Release 0.15.0 (2017-02-15)
* [knife-ec2:#484](https://github.com/chef/knife-ec2/pull/484) sleep for collecting windows password
* [knife-ec2:#481](https://github.com/chef/knife-ec2/pull/481) Updated readme for EC2 AMI list
* [knife-ec2:#482](https://github.com/chef/knife-ec2/pull/482) Allow search for EC2 AMIs
* [knife-ec2:#471](https://github.com/chef/knife-ec2/pull/471) Added support to include ec2 server id in the node name using `-N "www-server-%s" or  --chef-node-name "-www-server-%s"`
* [knife-ec2:#478](https://github.com/chef/knife-ec2/pull/478) Allow for hosts without public ip addresses
* [knife-ec2:#476](https://github.com/chef/knife-ec2/pull/476) Tag node in chef
* [knife-ec2:#458](https://github.com/chef/knife-ec2/pull/458) Fix where yes option wasn’t being passed to bootstrap
* [knife-ec2:#468](https://github.com/chef/knife-ec2/pull/468) In VPC mode use private IP when public IP and DNS not available 
* [knife-ec2:#464](https://github.com/chef/knife-ec2/pull/464) default value and desription is changed for --ebs-volume-type 

## Release 0.14.0 (2016-12-02)
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