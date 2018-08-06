<!---
This file is reset every time a new release is done. The contents of this file are for the currently unreleased version.

Example Note:

## Example Heading
Details about the thing that changed that needs to get included in the Release Notes in markdown.
-->

# knife-ec2 0.19.10 release notes:

Support for Ruby 2.2 and Chef 12.X has been removed as both are now end of life. This gem now requires Ruby 2.3 (Chef 13) or later, which ships in all supported releases of Chef-DK.

Credentials handling has been updated to use Amazon's credentials file unless keys are specified in the knife.rb/config.rb or via the command line. This is now the preferred method of authenticating knife-ec2 with AWS as it prevents credential credential sprawl and credentials showing up in shell history. The readme authentication section has been rewritten and expanded to touch on the various methods of authenticating this plugin.

The long ago deprecated `--distro` and `--template_file` flags for `knife ec2 server create` have been removed. These were no longer used by knife bootstrap so this should have zero impact on knife-ec2 users.

The fog-aws gem dependency has been loosened to allow fog-aws 1.0-3.X instead of just 1.X. This adds new instance types to `knife ec2 flavor list` and adds support for additional regions and availability zones previously not supported.

Remove the dependency on `mime-types` and `readline` gems, which don't appear to actually be used directly.

# knife-ec2 0.18.0 release notes:
In this release we have added separate features for tagging EC2 instances in AWS and Chef. Option `--aws-tag` is used for tagging the node in AWS and option `--chef-tag` is used for tagging the node in Chef. Subsequently the `--tag-node-in-chef` and `--tags` are now deprecated.

## Features added in knife-ec2 0.18.0
* Added support for tagging node in AWS as well as in Chef with separate options `--aws-tag` and `--chef-tag`. PR: [520](https://github.com/chef/knife-ec2/pull/520).

## Enhancement in knife-ec2 0.18.0
* No enhancements.
