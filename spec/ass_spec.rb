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
    FileUtils.rm_r File.expand_path('~/.ass')
  end

  it 'should be able to locally install a .dll' do
    ass(:list).should_not include('Dogs')
    ass :install, dll(:Dogs)
    ass(:list).should include('Dogs')
  end

end