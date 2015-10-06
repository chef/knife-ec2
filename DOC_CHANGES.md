<!---
This file is reset everytime when a new release is done. Contents of this file is for the currently unreleased version.
-->

# knife-ec2 doc changes

Documentation changes are given below for **knife-ec2 version 0.12.0**.

## `knife ec2 server create` subcommand changes

### SSH agent forwarding with --forward-agent option
The `--forward-agent` option has been added to the `knife ec2 server
create` subcommand. This enables SSH agent forwarding, and has the
same behavior during bootstrap of the created node as the
`--forward-agent` option of the [`knife bootstrap` subcommand](https://docs.chef.io/knife_bootstrap.html).

### WinRM security `--winrm-authentication-protocol` option
`knife-ec2`'s `server create` subcommand supports bootstrap via
the `WinRM` remote command protocol. The
`--winrm-authentication-protocol` option controls authentication to
the remote system (the bootstrapped node). This option's behavior is
covered in the
[knife-windows](https://github.com/chef/knife-windows/blob/v1.0.0/DOC_CHANGES.md)
subcommand documentation which has identically named option.

Note that with this change, the default authentication used for WinRM
communication specified by the `--winrm-authentication-protocol`
option is the `negotiate` protocol, which is different than that used
by previous versions of `knife-ec2`. This may lead to some
compatibility issues when using WinRM's plaintext transport
(`--winrm-transport` set to the default of `plaintext`) running from `knife ec2 server create`
from an operating system other than Windows.

To avoid problems with the `negotiate` protocol on a non-Windows
system, configure `--winrm-transport` to `ssl` to use SSL which also
improves the robustness against information disclosure or tampering
attacks.

You may also revert to previous authentication behavior by specifying `basic` for the
`--winrm-authentication-protocol` option. More details on this change
can be found in [documentation](https://github.com/chef/knife-windows/blob/v1.0.0/DOC_CHANGES.md#winrm-authentication-protocol-defaults-to-negotiate-regardless-of-name-formats) for `knife-windows`.

### Chef Client installation options on Windows
The following options are available for Windows systems:

* `--msi-url URL`: Optional. Used to override the location from which Chef
  Client is downloaded. If not specified, Chef Client is downloaded
  from the Internet -- this option allows downloading from a private network
  location for instance.
* `--install-as-service`: Install chef-client as a service on Windows
  systems
* `--bootstrap-install-command`: Optional. Instead of downloading Chef
  Client and installing it using a default installation command,
  bootstrap will invoke this command. If an image already has
  Chef Client installed, this command can be specified as empty
  (`''`), in which case no installation will be done and the rest of
  bootstrap will proceed as if it's already installed.

For more detail, see the [knife-windows documentation](https://docs.chef.io/plugin_knife_windows.html).


