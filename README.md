Knife EC2
=========
[![Gem Version](https://badge.fury.io/rb/knife-ec2.svg)](http://badge.fury.io/rb/knife-ec2)
[![Build Status](https://travis-ci.org/chef/knife-ec2.svg?branch=master)](https://travis-ci.org/chef/knife-ec2)
[![Dependency Status](https://gemnasium.com/chef/knife-ec2.svg)](https://gemnasium.com/chef/knife-ec2)

This is the official Chef Knife plugin for EC2. This plugin gives knife the ability to create, bootstrap, and manage EC2 instances.

* Documentation: <http://docs.chef.io/plugin_knife_ec2.html>
* Source: <http://github.com/chef/knife-ec2/tree/master>
* Issues: <https://github.com/chef/knife-ec2/issues>
* IRC: `#chef` and `#chef-hacking` on Freenode
* Mailing list: <http://lists.chef.io>

Note: Documentation needs to be updated in chef docs

Installation
------------

If you're using [ChefDK](http://downloads.chef.io/chef-dk/), simply install the
Gem:

```bash
chef gem install knife-ec2
```

If you're using bundler, simply add Chef and Knife EC2 to your `Gemfile`:

```ruby
gem 'chef'
gem 'knife-ec2'
```

If you are not using bundler, you can install the gem manually. Be sure you are running Chef 0.10.10 or higher, as earlier versions do not support plugins.

    $ gem install chef

This plugin is distributed as a Ruby Gem. To install it, run:

    $ gem install knife-ec2

Depending on your system's configuration, you may need to run this command with root privileges.


Configuration
-------------
In order to communicate with the Amazon's EC2 API you will have to tell Knife about your AWS Access Key and Secret Access Key. The easiest way to accomplish this is to create some entries in your `knife.rb` file:

```ruby
knife[:aws_access_key_id] = "Your AWS Access Key ID"
knife[:aws_secret_access_key] = "Your AWS Secret Access Key"
```

If your `knife.rb` file will be checked into a SCM system (ie readable by others) you may want to read the values from environment variables:

```ruby
knife[:aws_access_key_id] = ENV['AWS_ACCESS_KEY_ID']
knife[:aws_secret_access_key] = ENV['AWS_SECRET_ACCESS_KEY']
# Optional if you're using Amazon's STS
knife[:aws_session_token] = ENV['AWS_SESSION_TOKEN']
```

You also have the option of passing your AWS API Key/Secret into the individual knife subcommands using the `-A` (or `--aws-access-key-id`) `-K` (or `--aws-secret-access-key`) command options

```bash
# provision a new m1.small Ubuntu 10.04 webserver
$ knife ec2 server create -r 'role[webserver]' -I ami-7000f019 -f m1.small -A 'Your AWS Access Key ID' -K "Your AWS Secret Access Key"
```

If you are working with Amazon's command line tools, there is a good chance
you already have a file with these keys somewhere in this format:

    AWSAccessKeyId=Your AWS Access Key ID
    AWSSecretKey=Your AWS Secret Access Key


The new config file format used by Amazon's command line tools is also supported:

    [default]
    aws_access_key_id = Your AWS Access Key ID
    aws_secret_access_key = Your AWS Secret Access Key

In this case, you can point the <tt>aws_credential_file</tt> option to
this file in your <tt>knife.rb</tt> file, like so:

```ruby
knife[:aws_credential_file] = "/path/to/credentials/file/in/above/format"
```

If you have multiple profiles in your credentials file you can define which
profile to use. The `default` profile will be used if not supplied,

```ruby
knife[:aws_profile] = "personal"
```

Additionally the following options may be set in your `knife.rb`:

- flavor
- image
- availability_zone
- ssh_key_name
- aws_session_token
- region
- distro
- template_file

Using Cloud-Based Secret Data
-----------------------------
knife-ec2 now includes the ability to retrieve the encrypted data bag secret and validation keys directly from a cloud-based assets store (currently on S3 is supported). To enable this functionality, you must first upload keys to S3 and give them appropriate permissions. The following is a suggested set of IAM permissions required to make this work:

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
        "arn:aws:s3:::provisioning.bucket.com/chef/*"
      ]
    }
  ]
}
```

### Supported URL format
- `http` or `https` based: 'http://provisioning.bucket.com/chef/my-validator.pem'
- `s3` based:  's3://chef/my-validator.pem'

### Use the following configuration options in `knife.rb` to set the source URLs:
```ruby
knife[:validation_key_url] = 'http://provisioning.bucket.com/chef/my-validator.pem'
knife[:s3_secret] = 'http://provisioning.bucket.com/chef/encrypted_data_bag_secret'
```

### Alternatively, URLs can be passed directly on the command line:
- Validation Key: `--validation-key-url s3://chef/my-validator.pem`
- Encrypted Data Bag Secret: `--s3-secret s3://chef/encrypted_data_bag_secret`

Subcommands
-----------
This plugin provides the following Knife subcommands. Specific command options can be found by invoking the subcommand with a `--help` flag


#### `knife ec2 server create`
Provisions a new server in the Amazon EC2 and then perform a Chef bootstrap
(using the SSH or WinRM protocols). The goal of the bootstrap is to get Chef installed on the target system so it can run Chef Client with a Chef Server. The main assumption is a baseline OS installation exists (provided by the provisioning). It is primarily intended for Chef Client systems that talk to a Chef server.  The examples below create Linux and Windows instances:

    # Create some instances -- knife configuration contains the AWS credentials

    # A Linux instance via ssh
    knife ec2 server create -I ami-d0f89fb9 --ssh-key your-public-key-id -f m1.medium --ssh-user ubuntu --identity-file ~/.ssh/your-private-key

    # A Windows instance via the WinRM protocol -- --ssh-key is still required due to EC2 API operations that need it to grant access to the Windows instance
    # `--spot-price` option lets you specify the spot pricing
    knife ec2 server create -I ami-173d747e -G windows -f m1.medium --user-data ~/your-user-data-file -x '.\a_local_user' -P 'yourpassword' --ssh-key your-public-key-id --spot-price price-in-USD

View additional information on configuring Windows images for bootstrap in the documentation for [knife-windows](http://docs.chef.io/plugin_knife_windows.html).

##### Options for bootstrapping Windows

The `knife ec2 server create` command also supports the following
options for bootstrapping a Windows node after the VM s created:

    :winrm_password                The WinRM password
    :winrm_authentication_protocol Defaults to negotiate, supports kerberos, can be set to basic for debugging
    :winrm_transport               Defaults to plaintext, use ssl for improved privacy
    :winrm_port                    Defaults to 5985 plaintext transport, or 5986 for SSL
    :ca_trust_file                 The CA certificate file to use to verify the server when using SSL
    :winrm_ssl_verify_mode         Defaults to verify_peer, use verify_none to skip validation of the server certificate during testing
    :kerberos_keytab_file          The Kerberos keytab file used for authentication
    :kerberos_realm                The Kerberos realm used for authentication
    :kerberos_service              The Kerberos service used for authentication

#### `knife ec2 server delete`
Deletes an existing server in the currently configured AWS account. **By default, this does not delete the associated node and client objects from the Chef server. To do so, add the `--purge` flag**

#### `knife ec2 server list`
Outputs a list of all servers in the currently configured AWS account. **Note, this shows all instances associated with the account, some of which may not be currently managed by the Chef server.**

License and Authors
-------------------
- Author:: Adam Jacob (<adam@chef.io>)

```text
Copyright 2009-2015 Chef Software, Inc.

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
