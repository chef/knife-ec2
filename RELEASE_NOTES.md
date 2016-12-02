<!---
This file is reset every time a new release is done. The contents of this file are for the currently unreleased version.

Example Note:

## Example Heading
Details about the thing that changed that needs to get included in the Release Notes in markdown.
-->
# knife-ec2 0.13.0 release notes:

This release of `knife-ec2` adds feature to bootstrap the `Windows` instance without the need to pass `user-data`. Also, it adds support for users to pass AWS config file containing the AWS configurations like region information.

## Features added in knife-ec2 0.13.0

* `--[no-]create-ssl-listener` option to add `ssl listener` on Windows instance to bootstrap the instance through `winrm ssl transport` without the need for user to pass the `user-data`.
* Support for `~/.aws/config` file for reading aws configurations.
* Support to read `aws_session_token` from `~/.aws/credentials` file.
* Support for `ec2 classic link`, options are `--classic-link-vpc-id` and `--classic-link-vpc-security-groups-ids`.
* Support for `m4`, `d2`, `t2` and `g2` ebs encryption flavors.
