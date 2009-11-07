%w( rubygems spec fileutils thin capture sinatra/base ).each {|lib| require lib }

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

  def ass_config_dir
    File.expand_path('~/.ass')
  end

  def log
    File.file?(logfile) ? File.read(logfile) : ''
  end

  def ymlfile
    spec_file 'assemblies.yml'
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

  def start_example_ruby_web_server
    @pid = fork {
      $0 = 'Example ruby web application for testing ASS'
      Capture { Rack::Handler::Thin.run ExampleRubyWebServer, :Port => 15924 }
    }
    Process.detach(@pid)
  end

  def stop_example_ruby_web_server
    Process.kill 'INT', @pid
  end
end

class ExampleRubyWebServer < Sinatra::Base

  helpers do
    include AssTestingHelpers

    def render_search_results_for query
      results = []

      persisted_assemblies.each do |name, versions|
        if name.downcase.include?(query.downcase)
          results << name
        else
          versions.each do |version, info|
            if info['Description'] and info['Description'].downcase.include?(query.downcase)
              results << []
              break
            end
          end
        end
      end

      "Search Results: " + results.join(', ')
    end
  end

  before do
    File.open(logfile, 'w'){|log| log << params.to_yaml }
  end

  get '/' do
    if params[:q]
      render_search_results_for params[:q]
    else
      "This is an example web server for ASS, the .NET Assembly Management tool"
    end
  end

  post '/' do
    persist_uploaded_assembly(params)
    "Uploaded Assembly: #{ params['Name'] } #{ params['Version'] }\n Full params: #{ params[:file][:tempfile].path }"
  end

  get '/upload' do
    "<form action='/' method='post' enctype='multipart/form-data'>" +
    "  Name: <input type='text' name='Name' />" +
    "  <input type='file' name='file' />" +
    "  <input type='submit' />" +
    "</form>"
  end

  get '/*.dll' do
    name = params[:splat].first
    first_version_params = persisted_assemblies[name].first.last # first returns ['0.0.0.0', { params }]
    begin
      "You want to download #{ first_version_params['file'].inspect }"
    rescue Exception => ex
      "Exception: #{ ex.to_yaml }"
    end
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
