require File.dirname(__FILE__) + '/spec_helper'

describe 'ASS Server' do

  before(:all){ start_example_ruby_web_server }
  after(:all){  stop_example_ruby_web_server  }

  it 'should be able to push an assembly and have it POST the file and assembly info to a web server' do
    log.should_not include('Dogs')
    ass :push, dll(:Dogs)
    log.should include('Dogs')
  end

  it 'should be able to GET the results of a search request and display it (by Name)' do
    ass(:search, 'dogs').should_not include('Dogs')
    ass :push, dll(:Dogs)
    ass(:search, 'Dogs').should include('Dogs')
    ass(:search, 'dogs').should include('Dogs')
  end

  it 'should be able to GET the results of a search request and display it (by Description)' do
    ass(:search, '"and stuff"').should_not include('Dogs')
    ass :push, dll(:Dogs)
    ass(:search, '"And STUFF"').should include('Dogs')
    ass(:search, '"and stuff"').should include('Dogs')
  end

  it 'should be able to download and install an assembly from a remote server' do
    ass :push, dll(:Dogs) # push it up so we can install it
    ass(:list).should_not include('Dogs')
    ass :install, 'Dogs' # name should match
    ass(:list).should include('Dogs')
  end

  it 'should be able to download and install an assembly from a remote server (specific version)'

  it 'should be able to GET to show information about a remote assembly'

end
