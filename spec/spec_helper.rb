%w( rubygems spec fileutils thin capture ).each {|lib| require lib }

module AssTestingHelpers

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

  def ymlfile
    spec_file 'assemblies.yml'
  end

  def ass_config_dir
    File.expand_path('~/.ass')
  end

  def log
    File.file?(logfile) ? File.read(logfile) : ''
  end

  def persisted_assemblies
    File.file?(ymlfile) ? YAML.load_file(ymlfile) : {}
  end

  def persist_uploaded_assembly params
    assemblies = persisted_assemblies
    assemblies[params['Name']] ||= {}
    assemblies[params['Name']][params['Version']] = params

    File.open(ymlfile, 'w'){|f| f << assemblies.to_yaml }
  end

  def example_ruby_app
    lambda {|env|
      request  = Rack::Request.new(env)
      response = Rack::Response.new
      params   = request.params

      File.open(logfile, 'w'){|log| log << params.to_yaml } # write to log file

      # GET /q=
      if query = params['q']
        assembly_names = persisted_assemblies.keys.sort
        assembly_names.each do |name|
          response.write(name) if name.downcase.include?(query)
        end

      # POST /
      elsif uploaded_assembly = params['file']
        persist_uploaded_assembly(params)
        response.write "Uploaded Assembly: #{ params['Name'] } #{ params['Version'] }"

      # GET /
      else
        response.write "This is an example web server for ASS, the .NET Assembly Management tool"
      end

      response.finish
    }
  end

  def start_example_ruby_web_server
    @pid = fork {
      $0 = 'Example ruby web application for testing ASS'
      Capture { Rack::Handler::Thin.run example_ruby_app, :Port => 15924 }
    }
    Process.detach(@pid)
  end

  def stop_example_ruby_web_server
    Process.kill 'INT', @pid
  end
end

Spec::Runner.configure do |config|
  config.include(AssTestingHelpers)
  
  config.before(:each) do
    FileUtils.rm_rf ass_config_dir
    FileUtils.rm_f  logfile
    FileUtils.rm_f  ymlfile
  end
end
