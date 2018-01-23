<!---
This file is reset every time a new release is done. The contents of this file are for the currently unreleased version.

Example Note:

## Example Heading
Details about the thing that changed that needs to get included in the Release Notes in markdown.
-->

# knife-ec2 0.17.0 release notes:
In this release we have added features for add existing eni to server and added `--instance-initiated-shutdown-behavior`. There are a couple of bug fixes and enhancement as well.

## Features added in knife-ec2 0.17.0

* Added support to add existing eni to server while node creation using `--primary-eni` PR: [515](https://github.com/chef/knife-ec2/pull/515).

* Added support to set the `--instance-initiated-shutdown-behavior` with the option to set "stop" or "terminate". The default is "stop". PR: [514](https://github.com/chef/knife-ec2/pull/514).


## Enhancement in knife-ec2 0.17.0

* require `rb-readline` to avoid ruby 2.4 warnings about `Fixnum` PR: [513](https://github.com/chef/knife-ec2/pull/513)

## Fixed issue in knife-ec2 0.17.0

* Fix the review comments for the PR #514 PR: [516](https://github.com/chef/knife-ec2/pull/516) issue: [514](https://github.com/chef/knife-ec2/pull/514).

* Pass policy params into bootstrap config PR: [508](https://github.com/chef/knife-ec2/pull/508) issue: [494](https://github.com/chef/knife-ec2/issues/494).

* Update travis and loosen up development dependencies PR: [506](https://github.com/chef/knife-ec2/pull/506)