require File.expand_path('../../spec_helper', __FILE__)

#This spec can only be run separately from the rest due to inclusion of fog library in other specs.
#rspec spec/unit/s3_source_deps_spec.rb

describe 'Check Dependencies', :exclude => Object.constants.include?(:Fog) do
  before(:each) do
  end
  it 'should not load fog by default' do
    begin
      Fog::Storage::AWS.new()
    rescue Exception => e
      expect(e).to be_a_kind_of(NameError)
    end
  end

  it 'lazy loads fog' do
    begin
      Chef::Knife::S3Source.fetch('test')
    rescue Exception => e
      expect(e).to be_a_kind_of(ArgumentError)
    end
  end
end
