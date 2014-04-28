<!---
This file is reset everytime when a new release is done. Contents of this file is for the currently unreleased version.
-->

# knife-ec2 doc changes

## Command-line flag option --aws-session-token for EC2 STS Token support
The option `--aws-session-token` was added for all knife-ec2 subcommands to
enable federation use cases.

### options

```
--aws-session-token
```

Your AWS Session Token, for use with AWS STS Federation or Session Tokens.
This option is available for all subcommands.

## Command-line flag option --ssh-gateway changes
The option `--ssh-gateway` will now use settings such as the user identity or
proxy from your system's .ssh config if they aren not specified on the
knife-ec2 command-line. This allows for use cases such as the user identity
required to access the ssh gateway being different than the user identity
through which you are accessing the node that you are bootstrapping.

