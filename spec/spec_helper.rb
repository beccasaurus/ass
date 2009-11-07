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
        persisted_assemblies.each do |name, versions|
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
        persist_uploaded_assembly(params)
        response.write "Uploaded Assembly: #{ params['Name'] } #{ params['Version'] }"

      elsif request.path_info == '/upload'
        response.write "<form action='/' method='post' enctype='multipart/form-data'>"
        response.write "  Name: <input type='text' name='Name' />"
        response.write "  <input type='file' name='file' />"
        response.write "  <input type='submit' />"
        response.write "</form>"

      elsif request.path_info =~ %r{/(.*)\.dll}
        name = $1
        first_version_params = persisted_assemblies[name].first.last # first returns ['0.0.0.0', { params }]
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
