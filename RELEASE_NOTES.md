<!---
This file is reset every time a new release is done. The contents of this file are for the currently unreleased version.

Example Note:

## Example Heading
Details about the thing that changed that needs to get included in the Release Notes in markdown.
-->
# knife-ec2 0.11.0 release notes:
This release of `knife-ec2` adds features like spot pricing, EBS volume encryption support and some bug fixes. There is also a dependency update for the `fog` gem and 'em-winrm' dependency is removed.

Special thanks go to contributors **Erik Frey** for addressing
[knife-ec2:#94](https://github.com/chef/knife-ec2/pull/94) and **Igor Shpakov** for lazy loading fog library.

See the [CHANGELOG](https://github.com/opscode/knife-ec2/blob/master/CHANGELOG.md) for a list of all changes in this release, and review
[DOC_CHANGES.md](https://github.com/opscode/knife-ec2/blob/master/DOC_CHANGES.md) for relevant documentation updates.

Issues with `knife-ec2` should be reported in the issue system at
https://github.com/opscode/knife-ec2/issues. Learn more about how you can
contribute features and bug fixes to `knife-ec2` at https://github.com/opscode/knife-ec2/blob/master/CONTRIBUTING.md.

## Features added in knife-ec2 0.11.0

* Support for Spot Instances (from Erik Frey)
* Lazy loading of fog library (from Igor Shpakov)
* Support for EBS volume encryption in `knife-ec2 server create` options
* Added ability to use IAM role credentials

## knife-ec2 on RubyGems and Github
https://rubygems.org/gems/knife-ec2
https://github.com/opscode/knife-ec2

## Issues fixed in knife-ec2 0.11.0

* Update `fog` gem dependency to `fog v1.25`
* Remove 'em-winrm' gem dependency
* [knife-ec2:#273](https://github.com/chef/knife-ec2/pull/273) Remove -s option for data bag secret and subnets
* [knife-ec2:#265](https://github.com/chef/knife-ec2/pull/265) showing error message for incorrect option input
