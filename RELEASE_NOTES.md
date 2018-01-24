<!---
This file is reset every time a new release is done. The contents of this file are for the currently unreleased version.

Example Note:

## Example Heading
Details about the thing that changed that needs to get included in the Release Notes in markdown.
-->

# knife-ec2 0.17.0 release notes:
In this release we have added features for adding exisiting ENI to server using `--primary-eni option`. Also added option `--instance-initiated-shutdown-behavior` to stop or terminate the instance on shutdown. There are a couple of bug fixes and enhancement as well.

## Features added in knife-ec2 0.17.0

* Added support to add existing ENI to server while node creation using `--primary-eni` option. PR: [515](https://github.com/chef/knife-ec2/pull/515).

* Added support to set the `--instance-initiated-shutdown-behavior` with the option to set "stop" or "terminate" the instance on shutdown. The default is "stop". PR: [514](https://github.com/chef/knife-ec2/pull/514).


## Enhancement in knife-ec2 0.17.0

* require `rb-readline` to avoid ruby 2.4 warnings about `Fixnum` PR: [513](https://github.com/chef/knife-ec2/pull/513)