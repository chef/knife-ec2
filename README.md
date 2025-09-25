# Knife EC2
[![Gem Version](https://badge.fury.io/rb/knife-ec2.svg)](https://rubygems.org/gems/knife-ec2)
[![Build status](https://badge.buildkite.com/6dce7349d1291de0f8a8c68a78cb6829067d5e44bec7c4c552.svg?branch=master)](https://buildkite.com/chef-oss/chef-knife-ec2-master-verify)

This is the official Chef Knife plugin for Amazon EC2. This plugin gives knife the ability to create, bootstrap, and manage EC2 instances.
- Documentation: [https://github.com/chef/knife-ec2/blob/master/README.md](https://github.com/chef/knife-ec2/blob/master/README.md)
- Source: [https://github.com/chef/knife-ec2/tree/master](https://github.com/chef/knife-ec2/tree/master)
- Issues: [https://github.com/chef/knife-ec2/issues](https://github.com/chef/knife-ec2/issues)
- Mailing list: [https://discourse.chef.io/](https://discourse.chef.io/)

## Installation

We highly recommend using [Chef Workstation](https://downloads.chef.io/chef-workstation/), which includes knife-ec2 out of the box. If for some reason you can't use Chef Workstation you can manually install the gem.

If you're using bundler, simply add Chef and Knife EC2 to your `Gemfile`:

```ruby
gem 'knife-ec2'
```

If you are not using bundler, you can install the gem manually from Rubygems:

```bash
$ gem install knife-ec2
```

Depending on your system's configuration, you may need to run this command with root privileges.

## Configuration

In order to communicate with the Amazon's EC2 API you will need to pass Knife your AWS Access Key, Secret Access Key, and if using STS your session token. The knife-ec2 plugin supports multiple methods for configuring these credentials including:
  - AWS configuration / credential files (preferred method)
  - knife.rb / config.rb configuration files
  - environmental variables
  - command line arguments

### AWS Configuration / Credential Files

The preferred method of storing credentials for AWS is to use Amazon's own credential and configuration files. The files allow for multiple "profiles", each with their own set of credentials. Also since these credentials aren't stored in your knife.rb/config.rb files you don't have to worry about accidentally checking credentials into a git repository. The configs can be created by hand or generated automatically by running `aws configure` if the AWS Command Line Interface (awscli) is installed.


See Amazon's [Configuration and Credentials Files](https://docs.aws.amazon.com/cli/latest/userguide/cli-config-files.html) documentation for additional information on the file format and default locations for Linux/Mac & Windows hosts.

#### Alternative Config Files Location

If you're not storing the files in their default directory you'll need to specify the location in your `knife.rb`/`config.rb` files:

```ruby
knife[:aws_credential_file] = "/path/to/credentials/file"
knife[:aws_config_file] = "/path/to/configuration/file"
```
Since the Knife config file is just Ruby you can also avoid hardcoding your home directory, which creates a configuration that can be used for any user:

```ruby
knife[:aws_credential_file] = File.join(ENV['HOME'], "/.aws/credentials")
knife[:aws_config_file] = File.join(ENV['HOME'], "/path/to/configuration/file")
```

#### Specifying the AWS Profile

If you have multiple profiles in your credentials file you can define which profile to use. The `default` profile will be used if not supplied,

```ruby
knife[:aws_profile] = "personal"
```

### Config.rb / Knife.rb Configuration

If you prefer to keep all of your configuration in a single location with Chef you can store your Amazon EC2 credentials in Chef's `knife.rb` or `config.rb` files:

```ruby
knife[:aws_access_key_id] = "Your AWS Access Key ID"
knife[:aws_secret_access_key] = "Your AWS Secret Access Key"
```

Additionally if using AWS STS:

```ruby
knife[:aws_session_token] = "Your AWS Session Token"
```

Note: If your `knife.rb` or `config.rb` files will be checked into a source control management system, or are otherwise accessible by others, you may want to use one of the other configuration methods to avoid exposing your credentials.

### Environmental Variables

Knife-ec2 can also read your credentials from shell environmental variables. Export `AWS_ACCESS_KEY_ID`, `AWS_SECRET_ACCESS_KEY`, and `AWS_SESSION_TOKEN` variables in your shell then add the following configuration to your `knife.rb` file:

```ruby
knife[:aws_access_key_id] = ENV['AWS_ACCESS_KEY_ID']
knife[:aws_secret_access_key] = ENV['AWS_SECRET_ACCESS_KEY']
```

Additionally if using AWS STS:

```ruby
knife[:aws_session_token] = ENV['AWS_SESSION_TOKEN']
```

### CLI Arguments

You also have the option of passing your AWS API Key/Secret into the individual knife subcommands using the `--aws-access-key-id` and `--aws-secret-access-key` command options

Example of provisioning a new t2.micro Ubuntu 16.04 webserver:

```bash
$ knife ec2 server create -r 'role[webserver]' -I ami-5e8bb23b -f t2.micro --aws-access-key-id 'Your AWS Access Key ID' --aws-secret-access-key "Your AWS Secret Access Key" -ssh-key my_key_name --region us-west-2
```

Note: Passing credentials via the command line exposes the credentials in your shell's history and should be avoided unless absolutely necessary.

## Additional config.rb & knife.rb Configuration Options

The following configuration options may be set in your configuration file:
- flavor
- image
- availability_zone
- ssh_key_name
- aws_session_token
- region

## Using Cloud-Based Secret Data

knife-ec2 now includes the ability to retrieve the encrypted data bag secret and validation keys directly from a cloud-based assets store (currently only S3 is supported). To enable this functionality, you must first upload keys to S3 and give them appropriate permissions. The following is a suggested set of IAM permissions required to make this work:

```json
{
  "Statement": [
    {
      "Effect": "Allow",
      "Action": [
        "s3:Get*",
        "s3:List*"
      ],
      "Resource": [
        "arn:aws:s3:::example.com/chef/*"
      ]
    }
  ]
}
```

### Supported URL format

- `http` or `https` based: 'http://example.com/chef/my-validator.pem'
- `s3` based:  's3://chef/my-validator.pem'

### Use the following configuration options in `knife.rb` or `config.rb` to set the source URLs:

```ruby
knife[:validation_key_url] = 'http://example.com/chef/my-validator.pem'
knife[:s3_secret] = 'http://example.com/chef/encrypted_data_bag_secret'
```

### Alternatively, URLs can be passed directly on the command line:

- Validation Key: `--validation-key-url s3://chef/my-validator.pem`
- Encrypted Data Bag Secret: `--s3-secret s3://chef/encrypted_data_bag_secret`

## knife-ec2 Subcommands

This plugin provides the following Knife subcommands. Specific command options can be found by invoking the subcommand with a `--help` flag

### `knife ec2 server create`

Provisions a new server in the Amazon EC2 and then perform a Chef bootstrap (using the SSH or WinRM protocols). The goal of the bootstrap is to get Chef installed on the target system so it can run Chef Client with a Chef Server. The main assumption is a baseline OS installation exists (provided by the provisioning). It is primarily intended for Chef Client systems that talk to a Chef server.  The examples below create Linux and Windows instances:

```bash
# Create some instances -- knife configuration contains the AWS credentials

# A Linux instance via ssh
knife ec2 server create -I ami-d0f89fb9 --ssh-key your-public-key-id -f m1.medium --ssh-user ubuntu --identity-file ~/.ssh/your-private-key

# A Windows instance via the WinRM protocol -- --ssh-key is still required due to EC2 API operations that need it to grant access to the Windows instance
# `--spot-price` option lets you specify the spot pricing
knife ec2 server create -I ami-173d747e -G windows -f m1.medium --user-data ~/your-user-data-file -x '.\a_local_user' -P 'yourpassword' --ssh-key your-public-key-id --spot-price price-in-USD

# Pass --server-connect-attribute to specify the instance attribute that we will try to connect to via ssh/winrm
# Possible values of --server-connect-attribute: private_dns_name, private_ip_address, dns_name, public_ip_address
# If --server-connect-attribute is not specified, knife attempts to determine if connecting to the instance's public or private IP is most appropriate based on other settings
knife ec2 server create -I ami-173d747e -x ubuntu --server-connect-attribute public_ip_address
```

View additional information on configuring Windows images for bootstrap in the documentation for [knife-windows](https://docs.chef.io/plugin_knife_windows.html).

#### Adding server_id to the node name

Users can also include the ec2 server id in the node name by placing `%s` in the string passed to the `--chef-node-name` option. The %s is replaced by the ec2 server id dynamically.
e.g. `-N "www-server-%s" or  --chef-node-name "www-server-%s"`

#### Tagging node in Chef

Users can use option `--tag-node-in-chef` for tagging node in EC2 and chef both with `knife ec2 server create` command. If user does not pass this option, then the node will be tagged only in EC2.

#### Tagging EBS Volumes

Users can attach ebs volumes to a new instance being created with knife-ec2 using `--volume-tags Tag=Value[,Tag=Value...]`.


#### Bootstrap Windows (2012 R2 and above platform) instance without user-data through winrm ssl transport

Users can bootstrap the Windows instance without the need to provide the user-data. `knife-ec2` has the ability to bootstrap the Windows instance through `winrm protocol` using the `ssl` transport. This requires users to set `--winrm-ssl` option and `--winrm-no-verify-cert`. This will do the necessary winrm ssl transport configurations on the target node and the bootstrap will just work.

***Note***: Users also need to pass the `--security-group-ids` option with IDs of the security group(s) having the required ports opened like `5986` for winrm ssl transport. In case if `--security-group-ids` option is not passed then make sure that the default security group in your account has the required ports opened.

Below is the sample command to create a Windows instance and bootstrap it through `ssl` transport without passing any user-data:

```
knife ec2 server create -N chef-node-name -I your-windows-image -f flavor-of-server -x '.\a_local_user' -P 'yourpassword' --ssh-key your-public-key-id --winrm-ssl --winrm-no-verify-cert --security-group-ids your-security-groups -VV
```

#### Bootstrap Windows (2012 R2 and above platform) instance with user-data through winrm with negotiate transport

Users can bootstrap the Windows instance with the user-data. `knife-ec2` has the ability to bootstrap the Windows instance through `winrm protocol` using the `negotiate` transport. This requires users to set `--winrm-auth-method` option as `negotiate` and `--connection-protocol` option as `winrm` and `--user-data` file. USER DATA file contains winrm configurations which needs to be set for successful winrm communication. This will do the necessary winrm configurations on the target node and the bootstrap will just work.

***Note***: Users also need to pass the `--security-group-ids` option with IDs of the security group(s) having the required ports opened like `5985` for winrm with negotiate transport. In case if `--security-group-ids` option is not passed then make sure that the default security group in your account has the required ports opened.

Below is the sample command to create a Windows instance and bootstrap it through `negotiate` transport with passing user-data:

```
knife ec2 server create -N chef-node-name -I your-windows-image -f flavor-of-server -U '.\a_local_user' -P 'yourpassword' --ssh-key your-public-key-id --connection-protocol winrm --winrm-auth-method negotiate --user-data '\path\to\user-data-file' --security-group-ids your-security-groups -VV
```
Below is the content of user data which is required to set winrm configurations and important ports to get open for successful winrm communication to node.

```
<powershell>
# Allow script execution
Set-ExecutionPolicy -ExecutionPolicy RemoteSigned -Force
# PS Remoting and & winrm.cmd basic config
Enable-PSRemoting -Force -SkipNetworkProfileCheck
winrm quickconfig -q
$user = "username"
$password = "password"
net user /add $user $password
net localgroup administrators $user /add
winrm create winrm/config/Listener?Address=*+Transport=HTTP
# winrm set winrm/config/winrs '@{MaxMemoryPerShellMB="300"}'
winrm set winrm/config/winrs '@{MaxMemoryPerShellMB="1024"}'
winrm set winrm/config/winrs '@{MaxShellsPerUser="50"}'
winrm set winrm/config '@{MaxTimeoutms="1800000"}'
winrm set winrm/config/service '@{AllowUnencrypted="true"}'
winrm set winrm/config/service/auth '@{Basic="true"}'
netsh advfirewall firewall add rule name="WinRM 5985" protocol=TCP dir=in localport=5985 action=allow
netsh advfirewall firewall add rule name="WinRM 5986" protocol=TCP dir=in localport=5986 action=allow
NetSh Advfirewall set allprofiles state off
net stop winrm
sc.exe config winrm start=auto
net start winrm
</powershell>
```
#### Options for bootstrapping Windows

The `knife ec2 server create` command also supports the following options for bootstrapping a Windows node after the VM is created:

```
:connection_password           The WinRM password
:winrm_auth_method             Defaults to negotiate, supports kerberos, can be set to basic for debugging
:winrm_ssl                     SSL in the WinRM connection
:connection_port               Defaults to 5985 plaintext transport, or 5986 for SSL
:ca_trust_file                 The CA certificate file to use to verify the server when using SSL
:winrm_no_verify_cert          When flag is present, SSL cert will not be verified. Same as original mode of 'verify_none'
:kerberos_keytab_file          The Kerberos keytab file used for authentication
:kerberos_realm                The Kerberos realm used for authentication
:kerberos_service              The Kerberos service used for authentication
```
### `knife ec2 ami list`

This command provides the feature to list all EC2 AMIs. It also provides the feature to filter the AMIs based on owner and platform.

```
knife ec2 ami list
```

#### Options for AMIs list

- **Owner:**
  By default owner is aws-marketplace but you can specify following owner with the help of -o or --owner:

  **command:** knife ec2 ami list -o (options)

  ```
  :self                         Displays the list of AMIs created by the user.
  :aws-marketplace              Displays all AMIs form trusted vendors like Ubuntu, Microsoft, SAP, Zend as well as many open source offering.
  :micosoft                     Displays only Microsoft vendor AMIs.
  ```
- **Platform:**
  By default all platform AMIs are displayed, but you can filter your response by specifying the platform using -p or --platform:

  **command:** knife ec2 ami list -p (options)

  ```
  :Allowed platform             windows, ubuntu, debian, centos, fedora, rhel, nginx, turnkey, jumpbox, coreos, cisco, amazon, nessus
  ```
- **Search:**
  User can search any string into the description column by using -s or --search:

  **command:** knife ec2 ami list -s (search_keyword)

  ```
  :search_keyword             Any String or number
  ```

### `knife ec2 server list`

Outputs a list of all servers in the currently configured AWS account. **Note, this shows all instances associated with the account, some of which may not be currently managed by the Chef server.**

### `knife ec2 server delete`

Deletes an existing server in the currently configured AWS account. **By default, this does not delete the associated node and client objects from the Chef server. To do so, add the `--purge` flag**

## Development Documentation

All documentation is written using YARD. You can generate a by running:

```
rake docs
```

## Contributing

For information on contributing to this project please see our [Contributing Documentation](https://github.com/chef/chef/blob/master/CONTRIBUTING.md)

## License & Copyright

- Copyright:: Copyright (c) 2009-2019 Chef Software, Inc.
- License:: Apache License, Version 2.0

```text
Licensed under the Apache License, Version 2.0 (the "License");
you may not use this file except in compliance with the License.
You may obtain a copy of the License at

    http://www.apache.org/licenses/LICENSE-2.0

Unless required by applicable law or agreed to in writing, software
distributed under the License is distributed on an "AS IS" BASIS,
WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
See the License for the specific language governing permissions and
limitations under the License.
```
