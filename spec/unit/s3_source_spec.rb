require File.expand_path("../../spec_helper", __FILE__)
require "aws-sdk-s3"

describe Chef::Knife::S3Source do
  before(:each) do
    @bucket_name = "mybucket"
    @test_file_path = "path/file.pem"
    @test_file_content = "TEST CONTENT\n"
    @s3_connection = Aws::S3::Client.new(stub_responses: {
      list_buckets: { buckets: [{ name: @bucket_name }] },
      get_object: { body: @test_file_content },
    })

    @s3_source = Chef::Knife::S3Source.new
    allow(@s3_source).to receive(:s3_connection).and_return @s3_connection
  end

  context "for http URL format" do
    it "converts URI to path with leading / removed" do
      @s3_source.url = "http://s3.amazonaws.com/#{@bucket_name}/#{@test_file_path}"
      @s3_source.instance_eval { path }
      expect(@s3_source.instance_eval { path }).to eq(@test_file_path)
    end

    it "correctly retrieves the bucket name from the URI" do
      @s3_source.url = "http://s3.amazonaws.com/#{@bucket_name}/#{@test_file_path}"
      @s3_source.instance_eval { bucket }
      expect(@s3_source.instance_eval { bucket }).to eq(@bucket_name)
    end

    it "gets back the correct bucket contents" do
      @s3_source.url = "http://s3.amazonaws.com/#{@bucket_name}/#{@test_file_path}"
      expect(@s3_source.body).to eq(@test_file_content)
    end

    it "gets back a bucket object with bucket_obj" do
      @s3_source.url = "http://s3.amazonaws.com/#{@bucket_name}/#{@test_file_path}"
      @s3_source.instance_eval { bucket_obj }
      expect(@s3_source.instance_eval { bucket_obj.data }).to be_kind_of(Aws::S3::Types::GetObjectOutput)
    end
  end

  context "for s3 URL format" do
    it "correctly retrieves the bucket name from the URI" do
      @s3_source.url = "s3://#{@bucket_name}/#{@test_file_path}"
      @s3_source.instance_eval { bucket }
      expect(@s3_source.instance_eval { bucket }).to eq(@bucket_name)
    end

    it "gets back the correct bucket contents" do
      @s3_source.url = "s3://#{@bucket_name}/#{@test_file_path}"
      expect(@s3_source.body).to eq(@test_file_content)
    end

    it "gets back a bucket object with bucket_obj" do
      @s3_source.url = "s3://#{@bucket_name}/#{@test_file_path}"
      @s3_source.instance_eval { bucket_obj }
      expect(@s3_source.instance_eval { bucket_obj.data }).to be_kind_of(Aws::S3::Types::GetObjectOutput)
    end
  end
end
