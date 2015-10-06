<!---
This file is reset every time a new release is done. The contents of this file are for the currently unreleased version.

Example Note:

## Example Heading
Details about the thing that changed that needs to get included in the Release Notes in markdown.
-->
# knife-ec2 0.12.0 release notes:

This release of `knife-ec2` adds features like spot pricing, EBS volume encryption support and some bug fixes. There is also a dependency update for the `fog` gem and 'em-winrm' dependency is removed.

## Compatibility note for Windows nodes: `--winrm-authentication-protocol basic`
In this version of `knife-ec2`, the default authentication protocol
for Windows nodes is now `negotiate`for the `server create` subcommand. This can
cause bootstraps to fail if the remote Windows node is not configured
for `negotiate`. To work around this and retain the behavior of
previous releases, you can specify use `basic` authentication in your
`knife` configuration file or on the command line  as in
this example:

        knife ec2 server create -I ami-173d747e -G windows -f m1.medium --user-data ~/your-user-data-file -x 'a_local_user' -P 'yourpassword' --ssh-key your-public-key-id --winrm-authentication-protocol basic

## Acknowledgements
Our thanks go to contributor **Peer Allan** for adding
[knife-ec2:#305](https://github.com/chef/knife-ec2/pull/305). This
enables the use of standard AWS credential configuration from `~/.aws/credentials`.

## Release information

See the [CHANGELOG](https://github.com/chef/knife-ec2/blob/0.12.0/CHANGELOG.md) for a list of all changes in this release, and review
[DOC_CHANGES.md](https://github.com/chef/knife-ec2/blob/0.12.0/DOC_CHANGES.md) for relevant documentation updates.

Issues with `knife-ec2` should be reported in the issue system at
https://github.com/opscode/knife-ec2/issues. Learn more about how you can
contribute features and bug fixes to `knife-ec2` at https://github.com/opscode/knife-ec2/blob/master/CONTRIBUTING.md.

## Features added in knife-ec2 0.12.0

* Support for `~/.aws/credentials` credential configuration (Peer Allan)
* Validatorless bootstrap for Windows nodes
* --forward-agent ssh agent forwarding support
* `--msi-url`, `--install-as-service`, `--bootstrap-install-command`
  for Windows nodes

## knife-ec2 on RubyGems and Github
https://rubygems.org/gems/knife-ec2
https://github.com/opscode/knife-ec2

## Issues fixed in knife-ec2 0.11.0
See the [0.12.0 CHANGELOG](https://github.com/chef/knife-ec2/blob/0.12.0/CHANGELOG.md)
for the complete list of issues fixed in this release.
