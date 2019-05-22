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
      module ConnectionOptions

        def self.included(includer)
          includer.class_eval do

            deps do
              require "chef/knife/bootstrap"
              Chef::Knife::Bootstrap.load_deps
            end

            # Common connectivity options
            option :connection_user,
              short: "-U USERNAME",
              long: "--connection-user USERNAME",
              description: "Authenticate to the target host with this user account."

            option :connection_password,
              short: "-P PASSWORD",
              long: "--connection-password PASSWORD",
              description: "Authenticate to the target host with this password."

            option :connection_port,
              short: "-p PORT",
              long: "--connection-port PORT",
              description: "The port on the target node to connect to."

            option :connection_protocol,
              short: "-o PROTOCOL",
              long: "--connection-protocol PROTOCOL",
              description: "The protocol to use to connect to the target node.",
              in: Chef::Knife::Bootstrap::SUPPORTED_CONNECTION_PROTOCOLS

            option :max_wait,
              short: "-W SECONDS",
              long: "--max-wait SECONDS",
              description: "The maximum time to wait for the initial connection to be established."

            option :session_timeout,
              long: "--session-timeout SECONDS",
              description: "The number of seconds to wait for each connection operation to be acknowledged while running bootstrap.",
              default: 60

            # WinRM Authentication
            option :winrm_ssl_peer_fingerprint,
              long: "--winrm-ssl-peer-fingerprint FINGERPRINT",
              description: "SSL certificate fingerprint expected from the target."

            option :ca_trust_file,
              short: "-f CA_TRUST_PATH",
              long: "--ca-trust-file CA_TRUST_PATH",
              description: "The Certificate Authority (CA) trust file used for SSL transport."

            option :winrm_no_verify_cert,
              long: "--winrm-no-verify-cert",
              description: "Do not verify the SSL certificate of the target node for WinRM.",
              boolean: true

            option :winrm_ssl,
              long: "--winrm-ssl",
              description: "Use SSL in the WinRM connection."

            option :winrm_auth_method,
              short: "-w AUTH-METHOD",
              long: "--winrm-auth-method AUTH-METHOD",
              description: "The WinRM authentication method to use.",
              proc: Proc.new { |protocol| Chef::Config[:knife][:winrm_auth_method] = protocol },
              in: WINRM_AUTH_PROTOCOL_LIST

            option :winrm_basic_auth_only,
              long: "--winrm-basic-auth-only",
              description: "For WinRM basic authentication when using the 'ssl' auth method.",
              boolean: true

              # This option was provided in knife bootstrap windows winrm,
              # but it is ignored  in knife-windows/WinrmSession, and so remains unimplemeneted here.
              # option :kerberos_keytab_file,
              #   :short => "-T KEYTAB_FILE",
              #   :long => "--keytab-file KEYTAB_FILE",
              #   :description => "The Kerberos keytab file used for authentication",
              #   :proc => Proc.new { |keytab| Chef::Config[:knife][:kerberos_keytab_file] = keytab }

            option :kerberos_realm,
              short: "-R KERBEROS_REALM",
              long: "--kerberos-realm KERBEROS_REALM",
              description: "The Kerberos realm used for authentication.",
              proc: Proc.new { |protocol| Chef::Config[:knife][:kerberos_realm] = protocol }

            option :kerberos_service,
              short: "-S KERBEROS_SERVICE",
              long: "--kerberos-service KERBEROS_SERVICE",
              description: "The Kerberos service used for authentication.",
              proc: Proc.new { |protocol| Chef::Config[:knife][:kerberos_service] = protocol }

            ## SSH Authentication
            option :ssh_forward_agent,
              short: "-A",
              long: "--ssh-forward-agent",
              description: "Enable SSH agent forwarding.",
              boolean: true

            option :ssh_gateway,
              short: "-w GATEWAY",
              long: "--ssh-gateway GATEWAY",
              description: "The ssh gateway server. Any proxies configured in your ssh config are automatically used by default.",
              proc: Proc.new { |key| Chef::Config[:knife][:ssh_gateway] = key }

            option :ssh_gateway_identity,
              long: "--ssh-gateway-identity  SSH_GATEWAY_IDENTITY",
              description: "The SSH identity file used for gateway authentication.",
              proc: Proc.new { |key| Chef::Config[:knife][:ssh_gateway_identity] = key }

            option :ssh_identity_file,
              short: "-i IDENTITY_FILE",
              long: "--ssh-identity-file IDENTITY_FILE",
              description: "The SSH identity file used for authentication."

            option :ssh_verify_host_key,
              long: "--ssh-verify-host-key VALUE",
              description: "Verify host key. Default is 'always'.",
              in: %w{always accept_new accept_new_or_local_tunnel never}
          end
        end
      end
    end
  end
end
