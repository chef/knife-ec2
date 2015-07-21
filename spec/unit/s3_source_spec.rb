require File.expand_path('../../spec_helper', __FILE__)
require 'fog'

describe Chef::Knife::S3Source do
  before(:each) do
    @bucket_name = 'mybucket'
    @test_file_path = 'path/file.pem'
    @test_file_content = "TEST CONTENT\n"

    Fog.mock!

    {
      aws_access_key_id: 'aws_access_key_id',
      aws_secret_access_key: 'aws_secret_access_key'
    }.each do |key, value|
      Chef::Config[:knife][key] = value
    end

    fog = Fog::Storage::AWS.new(
      aws_access_key_id: 'aws_access_key_id',
      aws_secret_access_key: 'aws_secret_access_key'
    )
    test_dir_obj = fog.directories.create('key' => @bucket_name)
    test_file_obj = test_dir_obj.files.create('key' => @test_file_path)
    test_file_obj.body = @test_file_content
    test_file_obj.save

    @s3_connection = double(Fog::Storage::AWS)
    @s3_source = Chef::Knife::S3Source.new
  end

  context "for http URL format" do
    it 'converts URI to path with leading / removed' do
      @s3_source.url = "http://s3.amazonaws.com/#{@bucket_name}/#{@test_file_path}"
      @s3_source.instance_eval { path }
      expect(@s3_source.instance_eval { path }).to eq(@test_file_path)
    end

    it 'correctly retrieves the bucket name from the URI' do
      @s3_source.url = "http://s3.amazonaws.com/#{@bucket_name}/#{@test_file_path}"
      @s3_source.instance_eval { bucket }
      expect(@s3_source.instance_eval { bucket }).to eq(@bucket_name)
    end

    it 'gets back the correct bucket contents' do
      @s3_source.url = "http://s3.amazonaws.com/#{@bucket_name}/#{@test_file_path}"
      expect(@s3_source.body).to eq(@test_file_content)
    end

    it 'gets back a bucket object with bucket_obj' do
      @s3_source.url = "http://s3.amazonaws.com/#{@bucket_name}/#{@test_file_path}"
      @s3_source.instance_eval { bucket_obj }
      expect(@s3_source.instance_eval { bucket_obj }).to be_kind_of(Fog::Storage::AWS::Directory)
    end
  end

  context "for s3 URL format" do
    it 'correctly retrieves the bucket name from the URI' do
      @s3_source.url = "s3://#{@bucket_name}/#{@test_file_path}"
      @s3_source.instance_eval { bucket }
      expect(@s3_source.instance_eval { bucket }).to eq(@bucket_name)
    end

    it 'gets back the correct bucket contents' do
      @s3_source.url = "s3://#{@bucket_name}/#{@test_file_path}"
      expect(@s3_source.body).to eq(@test_file_content)
    end

    it 'gets back a bucket object with bucket_obj' do
      @s3_source.url = "s3://#{@bucket_name}/#{@test_file_path}"
      @s3_source.instance_eval { bucket_obj }
      expect(@s3_source.instance_eval { bucket_obj }).to be_kind_of(Fog::Storage::AWS::Directory)
    end
  end
end
