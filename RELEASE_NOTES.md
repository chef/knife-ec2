<!---
This file is reset every time a new release is done. The contents of this file are for the currently unreleased version.

Example Note:

## Example Heading
Details about the thing that changed that needs to get included in the Release Notes in markdown.
-->

# knife-ec2 0.16.0 release notes:
In this release we have added features for tagging EBS volumes and tagging node in Chef. There are a couple of bug fixes and enhancement as well.

## Features added in knife-ec2 0.16.0

* Added support to tag node details to chef while node creation using `--tag-node-in-chef` PR: [492](https://github.com/chef/knife-ec2/pull/492).

* Added support to tag EBS volumes while node creation using `--volume-tags Tag=Value[,Tag=Value...]` PR: [488](https://github.com/chef/knife-ec2/pull/488).


## Enhancement in knife-ec2 0.16.0

* Update list of instance types that support ebs-encryption PR: [503](https://github.com/chef/knife-ec2/pull/503)

* Enhanced Winrm cert to 10 year expiry PR: [496](https://github.com/chef/knife-ec2/pull/496).

* Improper alignment of EC2 flavor list command `knife ec2 flavor list` PR: [490](https://github.com/chef/knife-ec2/pull/490)

* Added new column description in EC2 AMIs list command `knife ec2 ami list` PR: [487](https://github.com/chef/knife-ec2/pull/487)

## Fixed issue in knife-ec2 0.16.0

* Update bundler to resolve travis failure PR: [502](https://github.com/chef/knife-ec2/pull/502)

* Fix issue Tag node in Chef PR: [492](https://github.com/chef/knife-ec2/pull/492) issue: [234](https://github.com/chef/knife-ec2/issues/234).

* Added support to handle long passwords in windows PR: [489](https://github.com/chef/knife-ec2/pull/489) issue: [470](https://github.com/chef/knife-ec2/issues/470)