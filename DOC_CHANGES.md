<!---
This file is reset everytime when a new release is done. Contents of this file is for the currently unreleased version.
-->

# knife-ec2 doc changes

## Command-line flag option --aws-session-token for EC2 STS Token support
The option --aws-session-token was added for all knife-ec2 subcommands to
enable federation use cases.

### options

```
--aws-session-token
```

Your AWS Session Token, for use with AWS STS Federation or Session Tokens.
This option is available for all subcommands.

   
