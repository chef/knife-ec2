require File.expand_path('../../spec_helper', __FILE__)
require 'fog'

describe Chef::Knife::S3Source do
  before(:each) do
    @bucket_name = 'my.bucket'
    @test_file_path = 'path/to/file.pem'
    @test_file_content = "TEST CONTENT\n"

    Fog.mock!
    @s3_connection = double(Fog::Storage::AWS)
    @s3_source = Chef::Knife::S3Source.new
    @fog = Fog::Storage::AWS.new
    @test_dir_obj = @fog.directories.create('key' => @bucket_name)
    @test_file_obj = @test_dir_obj.files.create('key' => @test_file_path)
    @test_file_obj.body = @test_file_content
    @test_file_obj.save

    @s3_source.url = "s3://#{@bucket_name}/#{@test_file_path}"
  end

  it 'converts URI to path with leading / removed' do
    @s3_source.instance_eval { path }
    @s3_source.instance_eval { path }.should eq(@test_file_path)
  end

  it 'correctly retrieves the bucket name from the URI' do
    @s3_source.instance_eval { bucket }
    @s3_source.instance_eval { bucket }.should eq(@bucket_name)
  end

  it 'gets back the correct bucket contents' do
    @s3_source.body.should eq(@test_file_content)
  end

  it 'gets back a bucket object with bucket_obj' do
    @s3_source.instance_eval { bucket_obj }
    @s3_source.instance_eval { bucket_obj }.should
      be_kind_of(Fog::Storage::AWS::Directory)
  end
end
