require File.expand_path("../spec_helper", __dir__)

# This spec can only be run separately from the rest due to inclusion of fog library in other specs.
# rspec spec/unit/s3_source_deps_spec.rb

describe "Check Dependencies", exclude: Object.constants.include?(:Aws) do
  it "should not load Aws::S3::Client by default" do

    Aws::S3::Client.new
  rescue Exception => e
    expect(e).to be_a_kind_of(NameError)

  end

  it "lazy loads Aws::S3::Client without required config" do

    knife_config = {}
    Chef::Knife::S3Source.fetch("test", knife_config)
  rescue Exception => e
    expect(e).to be_a_kind_of(ArgumentError)

  end

  it "lazy loads Aws::S3::Client with required config" do

    knife_config = {}
    knife_config[:aws_access_key_id] = "aws_access_key_id"
    knife_config[:aws_secret_access_key] = "aws_secret_access_key"
    knife_config[:region] = "test-region"
    Chef::Knife::S3Source.fetch("/test/testfile", knife_config)
  rescue Exception => e
    expect(e).to be_a_kind_of(Aws::Errors::NoSuchEndpointError)

  end
end
