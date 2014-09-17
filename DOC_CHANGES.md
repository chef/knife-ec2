<!---
This file is reset everytime when a new release is done. Contents of this file is for the currently unreleased version.
-->

# knife-ec2 doc changes

## SSH Gateway from SSH Config
Any available SSH Gateway settings in your SSH configuration file are now used
by default. This includes using any SSH keys specified for the target host.

## Pass seperate SSH Gateway key
You can pass an SSH key to be used for authenticating to the SSH Gateway with
the --ssh-gateway-identity option.


   
