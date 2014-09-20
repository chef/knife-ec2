<!---
This file is reset every time a new release is done. The contents of this file are for the currently unreleased version.

Example Note:

## Example Heading
Details about the thing that changed that needs to get included in the Release Notes in markdown.
-->
# knife-ec2 0.10.rc.0 release notes:
This release of `knife-ec2` adds improvements around ssh configuration and EC2
IOPS provisioning. There is also a dependency update for the `fog` and `knife-windows` gems
to improve support for additional EC2 capabilities and Windows authentication
enhancements respectively.

Our MVP for this release is **Michael Dellanoce**, who contributed improvements
that allow re-use of your existing SSH configuration with knife-ec2,
particularly useful when dealing with SSH gateways. Michael, thank you for
taking the time to develop this feature.

See the [CHANGELOG](https://github.com/opscode/knife-ec2/blob/master/CHANGELOG.md) for a list of all changes in this release, and review
[DOC_CHANGES.md](https://github.com/opscode/knife-ec2/blob/master/DOC_CHANGES.md) for relevant documentation updates.

Issues with `knife-ec2` should be reported in the issue system at
https://github.com/opscode/knife-ec2/issues. Learn more about how you can
contribute features and bug fixes to `knife-ec2` at https://github.com/opscode/knife-ec2/blob/master/CONTRIBUTING.md.

## Features added in knife-ec2 0.10.0

* Provisioned IOPS support
* SSH workstation configuration integration (from Michael Dellanoce and Victor Lin)

## knife-ec2 on RubyGems and Github
https://rubygems.org/gems/knife-ec2
https://github.com/opscode/knife-ec2

## Issues fixed in knife-ec2 0.10.0

* Update `knife-windows` gem dependency to `knife-windows 0.8.0` for improved Windows authentication integration
* Update `fog` gem dependency to `fog 1.23.0`
* [KNIFE-464](https://tickets.opscode.com/browse/KNIFE-466) Knife ec2 should use gateway from net::ssh config if available
* [KNIFE-422](https://tickets.opscode.com/browse/KNIFE-422) Knife ec2 server create doesn't respect identity file of gateway server from ssh\_config
