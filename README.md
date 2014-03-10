Knife EC2
=========
[![Gem Version](https://badge.fury.io/rb/knife-ec2.png)](http://badge.fury.io/rb/knife-ec2)
[![Build Status](https://travis-ci.org/opscode/knife-ec2.png?branch=master)](https://travis-ci.org/opscode/knife-ec2)
[![Dependency Status](https://gemnasium.com/opscode/knife-ec2.png)](https://gemnasium.com/opscode/knife-ec2)

This is the official Chef Knife plugin for EC2. This plugin gives knife the ability to create, bootstrap, and manage EC2 instances.

* Documentation: <http://docs.opscode.com/plugin_knife_ec2.html>
* Source: <http://github.com/opscode/knife-ec2/tree/master>
* Tickets/Issues: <http://tickets.opscode.com/browse/KNIFE>
* IRC: `#chef` and `#chef-hacking` on Freenode
* Mailing list: <http://lists.opscode.com>

Installation
------------
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
        
In this case, you can point the <tt>aws_credential_file</tt> option to
this file in your <tt>knife.rb</tt> file, like so:

```ruby        
knife[:aws_credential_file] = "/path/to/credentials/file/in/above/format"
```

Additionally the following options may be set in your `knife.rb`:

- flavor
- image
- availability_zone
- aws_ssh_key_id
- region
- distro
- template_file


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
    knife ec2 server create -I ami-173d747e -G windows -f m1.medium --user-data ~/your-user-data-file -x '.\a_local_user' -P 'yourpassword' --ssh-key your-public-key-id

View additional information on configuring Windows images for bootstrap in the documentation for [knife-windows](http://docs.opscode.com/plugin_knife_windows.html).

#### `knife ec2 server delete`
Deletes an existing server in the currently configured AWS account. **By default, this does not delete the associated node and client objects from the Chef server. To do so, add the `--purge` flag**

#### `knife ec2 server list`
Outputs a list of all servers in the currently configured AWS account. **Note, this shows all instances associated with the account, some of which may not be currently managed by the Chef server.**

#### `knife ec2 instance data`
Generates instance metadata in meant to be used with Opscode's custom AMIs. This will read your knife configuration `~/.chef/knife.rb` for the validation certificate and Chef server URL to use and output in JSON format. The subcommand also accepts a list of roles/recipes that will be in the node's initial run list.

**Note**: Using Opscode's custom AMIs reflect an older way of launching instances in EC2 for Chef and should be considered DEPRECATED. Leveraging this plugins's `knife ec2 server create` subcommands with a base AMIs directly from your Linux distribution (ie Ubuntu AMIs from Canonical) is much preferred and more flexible. Although this subcommand will remain, the Opscode custom AMIs are currently out of date.

In-depth usage instructions can be found on the [Chef Wiki](http://wiki.opscode.com/display/chef/EC2+Bootstrap+Fast+Start+Guide).

License and Authors
-------------------
- Author:: Adam Jacob (<adam@getchef.com>)

```text
Copyright 2009-2014 Opscode, Inc.

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
