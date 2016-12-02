<!---
This file is reset every time a new release is done. The contents of this file are for the currently unreleased version.

Example Note:

## Example Heading
Details about the thing that changed that needs to get included in the Release Notes in markdown.
-->

# knife-ec2 0.13.1 release notes:

This release of `knife-ec2` contains minor bug fixes.

## Features added in knife-ec2 0.13.1

* `--security-group-id` option to specify security group id for the server. User can use this opiton multiple times when specifying multiple security groups. e.g. -g sg-e985168d -g sg-e7f06383 -g sg-ec1b7e88.

* Added support to show flavor list in json format using `--format json` option.

***Note:*** The `--security-group-ids` option will be removed in future release. Use the new --security-group-id option.