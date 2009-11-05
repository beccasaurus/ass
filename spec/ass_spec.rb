require 'rubygems'
require 'spec'
require 'fileutils'

# helpers

def ass *commands
  `booi ass.boo #{ commands.join(' ') }`
end

def spec_file *args
  File.join File.dirname(__FILE__), *args
end

def dll name
  spec_file 'dll', "#{ name }.dll"
end

def logfile
  spec_file 'webserver.log'
end

def log
  File.file?(logfile) ? File.read(logfile) : ''
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

  describe 'POST to server' do

    before :all do
      FileUtils.rm_f logfile
      require 'thin'
      @pid = fork {
        $0 = 'Example ruby web application for testing ASS'
        app = lambda {|env|
          File.open(logfile, 'w'){|log| log << Rack::Request.new(env).params.to_yaml }
          [ 200, {}, ['Example web application for testing ASS'] ]
        }
        Rack::Handler::Thin.run app, :Port => 15924
      }
      Process.detach(@pid)
    end

    after :all do
      Process.kill 'INT', @pid
    end

    it 'should be able to push an assembly and have it POST the file and assembly info to a web server' do
      log.should_not include('Dogs')
      ass :push, dll(:Dogs)
      log.should include('Dogs')
    end

  end

end
