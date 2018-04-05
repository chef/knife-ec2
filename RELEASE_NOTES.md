<!---
This file is reset every time a new release is done. The contents of this file are for the currently unreleased version.

Example Note:

## Example Heading
Details about the thing that changed that needs to get included in the Release Notes in markdown.
-->

# knife-ec2 0.18.0 release notes:
In this release we have added features for tagging EC2 instances in AWS and Chef separately. Option `--aws-tag` is used for tagging node in AWS and option `--chef-tag` is used for tagging the node in Chef. Also options `--tag-node-in-chef` and `--tags` are deprecated from this release.

## Features added in knife-ec2 0.18.0
* Added support for tagging node in AWS as well as in Chef with separate options `--aws-tag` and `--chef-tag`. PR: [520](https://github.com/chef/knife-ec2/pull/520).

## Enhancement in knife-ec2 0.18.0
* No enhancements.
