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

  def ymlfile port
    spec_file "assemblies.#{ port }.yml"
  end

  def ass_config_dir
    File.expand_path('~/.ass')
  end

  def log
    File.file?(logfile) ? File.read(logfile) : ''
  end

  def persisted_assemblies port
    File.file?(ymlfile(port)) ? YAML.load_file(ymlfile(port)) : {}
  end

  def persist_uploaded_assembly port, params
    assemblies = persisted_assemblies(port)
    assemblies[params['Name']] ||= {}
    assemblies[params['Name']][params['Version']] = params

    File.open(ymlfile(port), 'w'){|f| f << assemblies.to_yaml }
  end

  def example_ruby_app
    lambda {|env|
      request  = Rack::Request.new(env)
      response = Rack::Response.new
      params   = request.params

      File.open(logfile, 'w'){|log| log << params.to_yaml } # write to log file

      # GET /q=
      if query = params['q']
        persisted_assemblies(request.port).each do |name, versions|
          if name.downcase.include?(query.downcase)
            response.write(name)
          else
            # check versions (for descriptions) ... no match on name
            versions.each do |version, info|
              if info['Description'] and info['Description'].downcase.include?(query.downcase)
                response.write(name)
                break
              end
            end
          end
        end

      # POST /
      elsif params['file']
        params['filepath'] = params['file'][:tempfile].path
        persist_uploaded_assembly(request.port, params)
        response.write "Uploaded Assembly: #{ params['Name'] } #{ params['Version'] }"

      elsif request.path_info == '/upload'
        response.write "<form action='/' method='post' enctype='multipart/form-data'>"
        response.write "  Name: <input type='text' name='Name' />"
        response.write "  <input type='file' name='file' />"
        response.write "  <input type='submit' />"
        response.write "</form>"

      elsif request.path_info =~ %r{/(.*)\.dll}
        name = $1
        first_version_params = persisted_assemblies(request.port)[name].first.last # first returns ['0.0.0.0', { params }]
        path = first_version_params['filepath']

        # taken from Rack::File#serving
        body = [ File.read(path) ]
        size = Rack::Utils.bytesize body.first

        return [ 200, {
          'Last-Modified'  => File.mtime(path).httpdate,
          'Content-Type'   => 'application/x-msdos-program',
          'Content-Length' => size.to_s
        }, body ]

      # GET /
      else
        response.write "This is an example web server for ASS, the .NET Assembly Management tool"
      end

      response.finish
    }
  end

  def example_server()   "http://localhost:15924" end
  def example_server_2() "http://localhost:15925" end

  def start_example_ruby_web_server2() start_example_ruby_web_server(15925) end
  def start_example_ruby_web_server port = 15924
    @server_pids ||= {}
    @server_pids[port] = fork {
      $0 = "Example ruby web application for testing ASS on port #{ port }"
      Capture { Rack::Handler::Thin.run example_ruby_app.clone, :Port => port }
    }
    Process.detach(@server_pids[port])
    sleep 0.5
  end

  def stop_example_ruby_web_server2() stop_example_ruby_web_server(15925) end
  def stop_example_ruby_web_server port = 15924
    Process.kill 'INT', @server_pids[port]
  end
end

Spec::Runner.configure do |config|
  config.include(AssTestingHelpers)
  
  config.before(:each) do
    FileUtils.rm_rf ass_config_dir
    FileUtils.rm_f  logfile
    FileUtils.rm_f  ymlfile(15924)
    FileUtils.rm_f  ymlfile(15925)
  end
end
