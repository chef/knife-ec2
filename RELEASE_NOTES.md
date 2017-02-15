<!---
This file is reset every time a new release is done. The contents of this file are for the currently unreleased version.

Example Note:

## Example Heading
Details about the thing that changed that needs to get included in the Release Notes in markdown.
-->

# knife-ec2 0.15.0 release notes:
In this release we have added a command to list EC2 AMIs. Also added a feature to append server_id to the chef-node-name. There are a couple of bug fixes as well.

## Features added in knife-ec2 0.15.0

* Added command to list EC2 AMIs using `knife ec2 ami list` PR: [482](https://github.com/chef/knife-ec2/pull/482)

* Added support to insert ec2 server id into node name using -N "<Node Name>%s" PR: [471](https://github.com/chef/knife-ec2/pull/471)

* Changed source of vm name to allow for hosts without public ip addresses PR: [478](https://github.com/chef/knife-ec2/pull/478)

* Automatically pass tags to Chef as well as EC2 PR: [476](https://github.com/chef/knife-ec2/pull/476)


## Fixed issue in knife-ec2 0.15.0

* Wait for Windows Admin password to be available PR: [484](https://github.com/chef/knife-ec2/pull/484), issue: [479](https://github.com/chef/knife-ec2/issues/479), issue: [453](https://github.com/chef/knife-ec2/issues/453)

* Fix where `--yes` option was not being passed to bootstrap PR: [458](https://github.com/chef/knife-ec2/pull/458)

* In VPC mode use private IP when public IP and DNS are not available PR: [468](https://github.com/chef/knife-ec2/pull/468), issue: [344](https://github.com/chef/knife-ec2/issues/344)

* Default value and description improved for `--ebs-volume-type` improved for clarity PR: [464](https://github.com/chef/knife-ec2/pull/464), issue: [450](https://github.com/chef/knife-ec2/issues/450), issue [451](https://github.com/chef/knife-ec2/issues/451)
