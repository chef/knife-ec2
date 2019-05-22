#
# Author:: Vivek Singh (vsingh@chef.io)
#
# Copyright:: Copyright 2016-2019 Chef Software, Inc.
# License:: Apache License, Version 2.0
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#     http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.
#

class Chef
  class Knife
    class Bootstrap
      module CommonOptions

        def self.included(includer)
          includer.class_eval do

            deps do
              require "chef/knife/bootstrap"
              Chef::Knife::Bootstrap.load_deps
            end

            # client.rb content via chef-full/bootstrap_context
            option :bootstrap_version,
              long: "--bootstrap-version VERSION",
              description: "The version of #{Chef::Dist::PRODUCT} to install.",
              proc: lambda { |v| Chef::Config[:knife][:bootstrap_version] = v }

            option :channel,
              long: "--channel CHANNEL",
              description: "Install from the given channel. Default is 'stable'.",
              default: "stable",
              in: %w{stable current unstable}

            # client.rb content via chef-full/bootstrap_context
            option :bootstrap_proxy,
              long: "--bootstrap-proxy PROXY_URL",
              description: "The proxy server for the node being bootstrapped.",
              proc: Proc.new { |p| Chef::Config[:knife][:bootstrap_proxy] = p }

            # client.rb content via bootstrap_context
            option :bootstrap_proxy_user,
              long: "--bootstrap-proxy-user PROXY_USER",
              description: "The proxy authentication username for the node being bootstrapped."

            # client.rb content via bootstrap_context
            option :bootstrap_proxy_pass,
              long: "--bootstrap-proxy-pass PROXY_PASS",
              description: "The proxy authentication password for the node being bootstrapped."

            # client.rb content via bootstrap_context
            option :bootstrap_no_proxy,
              long: "--bootstrap-no-proxy [NO_PROXY_URL|NO_PROXY_IP]",
              description: "Do not proxy locations for the node being bootstrapped; this option is used internally by Chef.",
              proc: Proc.new { |np| Chef::Config[:knife][:bootstrap_no_proxy] = np }

            # client.rb content via bootstrap_context
            option :bootstrap_template,
              short: "-t TEMPLATE",
              long: "--bootstrap-template TEMPLATE",
              description: "Bootstrap #{Chef::Dist::PRODUCT} using a built-in or custom template. Set to the full path of an erb template or use one of the built-in templates."

            # client.rb content via bootstrap_context
            option :node_ssl_verify_mode,
              long: "--node-ssl-verify-mode [peer|none]",
              description: "Whether or not to verify the SSL cert for all HTTPS requests.",
              proc: Proc.new { |v|
                valid_values = %w{none peer}
                unless valid_values.include?(v)
                  raise "Invalid value '#{v}' for --node-ssl-verify-mode. Valid values are: #{valid_values.join(", ")}"
                end
                v
              }

            # bootstrap_context - client.rb
            option :node_verify_api_cert,
              long: "--[no-]node-verify-api-cert",
              description: "Verify the SSL cert for HTTPS requests to the #{Chef::Dist::SERVER_PRODUCT} API.",
              boolean: true

            # runtime - sudo settings (train handles sudo)
            option :preserve_home,
              long: "--sudo-preserve-home",
              description: "Preserve non-root user HOME environment variable with sudo.",
              boolean: true

            # runtime - sudo settings (train handles sudo)
            option :use_sudo,
              long: "--sudo",
              description: "Execute the bootstrap via sudo.",
              boolean: true

            # runtime - sudo settings (train handles sudo)
            option :use_sudo_password,
              long: "--use-sudo-password",
              description: "Execute the bootstrap via sudo with password.",
              boolean: false

            # runtime - client_builder
            option :chef_node_name,
              short: "-N NAME",
              long: "--node-name NAME",
              description: "The node name for your new node."

            # runtime - client_builder - set runlist when creating node
            option :run_list,
              short: "-r RUN_LIST",
              long: "--run-list RUN_LIST",
              description: "Comma separated list of roles/recipes to apply.",
              proc: lambda { |o| o.split(/[\s,]+/) },
              default: []

            # runtime - client_builder - set policy name when creating node
            option :policy_name,
              long: "--policy-name POLICY_NAME",
              description: "Policyfile name to use (--policy-group must also be given).",
              default: nil

            # runtime - client_builder - set policy group when creating node
            option :policy_group,
              long: "--policy-group POLICY_GROUP",
              description: "Policy group name to use (--policy-name must also be given).",
              default: nil

            # runtime - client_builder -  node tags
            option :tags,
              long: "--tags TAGS",
              description: "Comma separated list of tags to apply to the node.",
              proc: lambda { |o| o.split(/[\s,]+/) },
              default: []

            # bootstrap template
            option :first_boot_attributes,
              short: "-j JSON_ATTRIBS",
              long: "--json-attributes",
              description: "A JSON string to be added to the first run of #{Chef::Dist::CLIENT}.",
              proc: lambda { |o| Chef::JSONCompat.parse(o) },
              default: nil

            # bootstrap template
            option :first_boot_attributes_from_file,
              long: "--json-attribute-file FILE",
              description: "A JSON file to be used to the first run of #{Chef::Dist::CLIENT}.",
              proc: lambda { |o| Chef::JSONCompat.parse(File.read(o)) },
              default: nil

            # Note that several of the below options are used by bootstrap template,
            # but only from the passed-in knife config; it does not use the
            # config from the CLI for those values.  We cannot always used the merged
            # config, because in some cases the knife keys thIn those cases, the option
            # will have a proc that assigns the value into Chef::Config[:knife]

            # bootstrap template
            # Create ohai hints in /etc/chef/ohai/hints, fname=hintname, content=value
            option :hint,
              long: "--hint HINT_NAME[=HINT_FILE]",
              description: "Specify an Ohai hint to be set on the bootstrap target. Use multiple --hint options to specify multiple hints.",
              proc: Proc.new { |h|
                Chef::Config[:knife][:hints] ||= Hash.new
                name, path = h.split("=")
                Chef::Config[:knife][:hints][name] = path ? Chef::JSONCompat.parse(::File.read(path)) : Hash.new
              }

            # bootstrap override: url of a an installer shell script touse in place of omnitruck
            # Note that the bootstrap template _only_ references this out of Chef::Config, and not from
            # the provided options to knife bootstrap, so we set the Chef::Config option here.
            option :bootstrap_url,
              long: "--bootstrap-url URL",
              description: "URL to a custom installation script.",
              proc: Proc.new { |u| Chef::Config[:knife][:bootstrap_url] = u }

            option :msi_url, # Windows target only
              short: "-m URL",
              long: "--msi-url URL",
              description: "Location of the #{Chef::Dist::PRODUCT} MSI. The default templates will prefer to download from this location. The MSI will be downloaded from #{Chef::Dist::WEBSITE} if not provided (Windows).",
              default: ""

            # bootstrap override: Do this instead of our own setup.sh from omnitruck. Causes bootstrap_url to be ignored.
            option :bootstrap_install_command,
              long: "--bootstrap-install-command COMMANDS",
              description: "Custom command to install #{Chef::Dist::PRODUCT}.",
              proc: Proc.new { |ic| Chef::Config[:knife][:bootstrap_install_command] = ic }

            # bootstrap template: Run this command first in the bootstrap script
            option :bootstrap_preinstall_command,
              long: "--bootstrap-preinstall-command COMMANDS",
              description: "Custom commands to run before installing #{Chef::Dist::PRODUCT}.",
              proc: Proc.new { |preic| Chef::Config[:knife][:bootstrap_preinstall_command] = preic }

            # bootstrap template
            option :bootstrap_wget_options,
              long: "--bootstrap-wget-options OPTIONS",
              description: "Add options to wget when installing #{Chef::Dist::PRODUCT}.",
              proc: Proc.new { |wo| Chef::Config[:knife][:bootstrap_wget_options] = wo }

            # bootstrap template
            option :bootstrap_curl_options,
              long: "--bootstrap-curl-options OPTIONS",
              description: "Add options to curl when install #{Chef::Dist::PRODUCT}.",
              proc: Proc.new { |co| Chef::Config[:knife][:bootstrap_curl_options] = co }

            # chef_vault_handler
            option :bootstrap_vault_file,
              long: "--bootstrap-vault-file VAULT_FILE",
              description: "A JSON file with a list of vault(s) and item(s) to be updated."

            # chef_vault_handler
            option :bootstrap_vault_json,
              long: "--bootstrap-vault-json VAULT_JSON",
              description: "A JSON string with the vault(s) and item(s) to be updated."

            # chef_vault_handler
            option :bootstrap_vault_item,
              long: "--bootstrap-vault-item VAULT_ITEM",
              description: 'A single vault and item to update as "vault:item".',
              proc: Proc.new { |i|
                (vault, item) = i.split(/:/)
                Chef::Config[:knife][:bootstrap_vault_item] ||= {}
                Chef::Config[:knife][:bootstrap_vault_item][vault] ||= []
                Chef::Config[:knife][:bootstrap_vault_item][vault].push(item)
                Chef::Config[:knife][:bootstrap_vault_item]
              }
          end
        end
      end
    end
  end
end
