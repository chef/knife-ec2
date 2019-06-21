require File.expand_path("../../spec_helper", __FILE__)

# This spec can only be run separately from the rest due to inclusion of fog library in other specs.
# rspec spec/unit/s3_source_deps_spec.rb

describe "Check Dependencies", exclude: Object.constants.include?(:Aws) do
  it "should not load Aws::S3::Client by default" do
    begin
      Aws::S3::Client.new
    rescue Exception => e
      expect(e).to be_a_kind_of(NameError)
    end
  end

  it "lazy loads Aws::S3::Client without required config" do
    begin
      Chef::Knife::S3Source.fetch("test")
    rescue Exception => e
      expect(e).to be_a_kind_of(NoMethodError)
    end
  end

  it "lazy loads Aws::S3::Client with required config" do
    begin
      Chef::Config[:knife][:aws_access_key_id] = "aws_access_key_id"
      Chef::Config[:knife][:aws_secret_access_key] = "aws_secret_access_key"
      Chef::Config[:knife][:region] = "test-region"
      Chef::Knife::S3Source.fetch("test")
    rescue Exception => e
      expect(e).to be_a_kind_of(ArgumentError)
    end
  end
end
