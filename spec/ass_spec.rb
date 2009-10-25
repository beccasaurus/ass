require 'rubygems'
require 'spec'
require 'fileutils'

# helpers

def ass *commands
  `booi ass.boo #{ commands.join(' ') }`
end

def dll name
  File.join File.dirname(__FILE__), 'dll', "#{ name }.dll"
end

# specs

describe 'ASS' do

  before do
    FileUtils.rm_rf File.expand_path('~/.ass')
  end

  it 'should be able to locally install a .dll' do
    ass(:list).should_not include('Dogs')
    ass :install, dll(:Dogs)
    ass(:list).should include('Dogs')
  end

  it 'should be able to uninstall an assembly' do
    ass :install, dll(:Dogs)
    ass(:list).should include('Dogs')
    
    ass :uninstall, :Dogs
    ass(:list).should_not include('Dogs')
  end

  it "should be able to show an installed assembly's info" do
    ass(:show, :Dogs).should_not include('dogs and stuff')
    ass :install, dll(:Dogs)
    ass(:show, :Dogs).should include('dogs and stuff')
  end

end
