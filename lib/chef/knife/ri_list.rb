#
# Author:: Jimmy Coppens (jimmy@yhmg.com)
# Copyright:: Copyright (c) 2010-2011 Opscode, Inc.
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
require 'chef/knife/ec2_base'

class Chef
    class Knife
        class RiList < Knife
            
            include Knife::Ec2Base
            
            banner "knife ri list - List all reserved instance leases defined in the aws cloud"
            
            def build_ec2Map
                ec2Servers = connection.servers
                
                hash_map = ec2Servers.inject({}) do |hash, o|
                  if o.state == "running"
                      if o.vpc_id
                          vpc_or_not = " vpc"
                      else
                          vpc_or_not = " ec2"
                      end
                      
                      key = o.flavor_id.to_s + " " + o.availability_zone.to_s + vpc_or_not
                      hash[key] ||= 0
                      hash[key] += 1
                  end

                  hash

                end
                
                hash_map
            
            end

            def build_riMap(ri_leases)
                
                hash_map = ri_leases.inject({}) do |hash, o|
                    if o["reservedInstancesId"]

                      if o["productDescription"].to_s == "Linux/UNIX (Amazon VPC)"
                          vpc_or_not = " vpc"
                          else
                          vpc_or_not = " ec2"
                      end
                      
                      key = o["instanceType"].to_s + " " + o["availabilityZone"].to_s + vpc_or_not 
                      hash[key] ||= 0
                      hash[key] += o["instanceCount"].to_i
                    end
                      hash
                end

                hash_map
            end
            
            def lease_is_full(resInst, hash_map, hash_map_ri)

                if hash_map[ resInst  ]
                    
                    if (hash_map[ resInst ]) >= (hash_map_ri [ resInst ])
                        true
                    else
                        false
                    end
                else
                    false
                end
            end
 
            def run
                $stdout.sync = true

                validate!
                
                ri_list = [
                ui.color('InstanceType', :bold),
                ui.color('AvailabilityZone', :bold),
                ui.color('Product', :bold),
                ui.color('ResInstanceCount', :bold),
                ui.color('InstanceDifference', :bold),
                ].flatten.compact
                
                output_column_count = ri_list.length
                
                ri_leases = connection.describe_reserved_instances("state"=>"active").body["reservedInstancesSet"]

                hash_map = build_ec2Map
                hash_map_ri = build_riMap(ri_leases)

                hash_map_ri.each do |resInst, value|
                        
                            color = lease_is_full(resInst, hash_map, hash_map_ri) ? :blue : :red
                        
                        
                            ri_list << ui.color(
                                                resInst.split(" ")[0].to_s,
                                                color
                                                )
                             ri_list << ui.color(
                                                 resInst.split(" ")[1].to_s,
                                                 color
                                                 )
                            ri_list << ui.color(
                                                resInst.split(" ")[2].to_s,
                                                color
                                                )
                            ri_list <<  ui.color(
                                                value.to_s,
                                                color
                                                )
                            ri_list << ui.color((value.to_i - hash_map[resInst].to_i).to_s, color)
                        end
                
                puts ui.list(ri_list, :uneven_columns_across, output_column_count)
                
            end
        end
    end
end

