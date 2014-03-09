<!---
This file is reset everytime when a new release is done. Contents of this file is for the currently unreleased version.
-->

# knife-ec2 doc changes

## Command-line flag option --associate-ip for server create
The option --associate-ip was added to the knife-ec2 server create
subcommand.

### server create

### options

```
--associate-public-ip 
```

Associate public IP address to the VPC instance so that the public IP is available
during bootstrapping. Only valid with VPC instances.
   
