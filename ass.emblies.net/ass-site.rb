#! /usr/bin/env ruby
%w( rubygems sinatra haml sass dm-core dm-validations dm-timestamps dm-aggregates aws/s3 ).each {|lib| require lib }

use Rack::Session::Cookie

class User
  include DataMapper::Resource

  has n, :assemblies

  property :id,    Serial
  property :email, String

  def to_s() email end
end

class Assembly
  include DataMapper::Resource

  belongs_to :user
  has n,     :versions

  property :id,   Serial
  property :name, String

  def self.search query
    all :name.like => "%#{ query }%"
  end

  def latest_version
    versions.last
  end

  def info
    latest_version.title || latest_version.description || latest_version.product
  end

  def to_s()  name      end
  def path() "/#{name}" end
end

class Version
  include DataMapper::Resource

  belongs_to :assembly

  property :id,          Serial
  property :copyright,   String, :length => 255
  property :fullname,    String, :length => 255
  property :product,     String, :length => 255
  property :company,     String, :length => 255
  property :title,       String, :length => 255
  property :trademark,   String, :length => 255
  property :description, String, :length => 255
  property :version,     String, :length => 255
  property :created_at, DateTime

  def self.search query
    q = "%#{ query }%"
    all :conditions => ['description LIKE ? OR title LIKE ? OR product LIKE ? OR company LIKE ?', q, q, q, q]
  end

  def download_path
    "http://assemblies.s3.amazonaws.com/#{ dll_name }"
  end

  def name()     assembly.name                end
  def to_s()     "#{ name } #{ version }"     end
  def path()     "/#{name}/#{ version }"      end
  def dll_name() "#{ name }-#{ version }.dll" end
end

configure do
  dev_db = "sqlite3://#{ File.expand_path(File.dirname(__FILE__) + '/development.sqlite3') }"
  DataMapper.setup :default, ENV['DATABASE_URL'] || dev_db
  DataMapper.auto_upgrade!

  AWS::S3::Base.establish_connection! :access_key_id     => ENV['S3_KEY'],
                                      :secret_access_key => ENV['S3_SECRET']
end

helpers do
  def login_as user
    session.clear
    @user = nil
    session[:user_id] = user.id if user
  end

  def current_user() @user ||= User.get(session[:user_id]) end

  def logged_in?() !! current_user end

  def login_as_email(email)
    @user = User.first(:email => params[:email]) || User.create(:email => params[:email])
    if @user
      login_as @user
      redirect '/dashboard'
    else
      redirect '/'
    end
  end

  def cli?
    request.user_agent.nil? # include?('ASS')
  end

  def hhaml view
    haml view, :layout => (! cli?)
  end

end

# HOME / SEARCH
get '/' do
  if query = params[:q]
    @assemblies = Assembly.search(query)
    @versions   = Version.search(query)
    @assemblies = ( @assemblies + @versions.map {|v| v.assembly } ).uniq[0..19]
    hhaml(cli? ? :cli_results : :results)
  else
    hhaml :index
  end
end

get '/assemblies' do
  @assemblies = Assembly.all :limit => 20
  hhaml :results
end

get('/signup'){ hhaml :signup }
get('/login'){  hhaml :login }
post('/signup'){ login_as_email }
post('/login'){  login_as_email }
get('/logout'){ login_as nil; redirect '/' }
get('/dashboard'){ @assemblies = current_user.assemblies; hhaml :dashboard }
get('/new'){ hhaml :upload }

get('/styles.css'){ content_type 'text/css'; sass :stylesheet }

# UPLOAD
post '/' do
  unless logged_in? # default to remi@remitaylor.com for now ...
    user = User.first(:email => 'remi@remitaylor.com') || User.create(:email => 'remi@remitaylor.com')
    login_as user
  end

  # downcase all param keys
  p = params.dup.inject({}){|all, key_value| all[key_value[0].downcase] = key_value[1]; all }

  if p['name'] and p['version'] and p['file'][:tempfile]

    bytes   = p['file'][:tempfile].read
    name    = p['name'].downcase
    version = p['version'].downcase

    puts "name and version: #{ name } #{ version }"
    puts "size: #{ bytes.length }"

    if @ass = Assembly.first(:name => name)
      @version = @ass.versions.new(:version => version) if @ass.user == current_user
    else
      @ass     = current_user.assemblies.create(:name => name)
      @version = @ass.versions.new(:version => version)
    end
    
    if @version
      %w( copyright fullname product company title trademark description version ).each do |param|
        @version.send("#{ param }=", p[param]) if @version.respond_to?("#{ param }=")
      end
      @version.save

      AWS::S3::S3Object.store @version.dll_name, bytes, 'assemblies', :access => :public_read
      redirect @version.path
    else
      raise "Something didn't work."
    end
  else
    raise "Not enough parameters passed.  Need to atleast pass Name, Version, and the assembly file"
  end
end

get '/:name/:version.dll' do
  @assembly = Assembly.first :name.like => params[:name].downcase
  @version  = @assembly.versions.detect {|version| version.version == params[:version].downcase }
  redirect @version.download_path
end

get '/:name/:version' do
  @assembly = Assembly.first :name.like => params[:name].downcase
  @version  = @assembly.versions.detect {|version| version.version == params[:version].downcase }
  haml :version
end

get '/:name.dll' do
  @assembly = Assembly.first :name.like => params[:name].downcase
  redirect @assembly.latest_version.download_path
end

get '/:name' do
  @assembly = Assembly.first :name.like => params[:name].downcase
  haml :assembly
end

__END__

@@ layout
!!! XML
!!!
%html
  %head
    %title ASS :: .NET Assembly Management
    %link{ :rel => 'stylesheet', :type => 'text/css', :href => '/styles.css' }

  %body
    #container

      #header
  
        #logo
          %a{ :href => '/' }
            %h1 ASS
            %h2 The .NET Assembly Assembly Management System

        #nav
          %ul
            %li
              %a{ :href => '/assemblies' } assemblies
            - if logged_in?
              %li
                %a{ :href => '/dashboard' } dashboard
              %li
                %a{ :href => '/logout' } logout
            - else
              %li
                %a{ :href => '/login' } login
              %li
                %a{ :href => '/signup' } signup

        #search
          %form{ :action => '/', :method => 'get' }
            %input{ :type => 'text', :name => 'q' }
            %input{ :type => 'submit', :value => 'Search' }

      #content= yield

      #footer
        Created by 
        %a{ :href => 'http://remi.org', :target => '_blank' } remi 
        of 
        %a{ :href => 'http://devfu.com', :target => '_blank' } Dev Fu 
        for 
        %a{ :href => 'http://desertcodecamp.com', :target => '_blank' } Desert Code Camp
        2009

@@ index
%h1 ASS.emblies.NET
%p Foo and bar and foo and them this and that
%ul
  %li You can use this to do that
  %li And if I were to do something then this would be the something
  %li And potentially this or something this too
%p Foo and bar and foo and them this and that


@@ signup
%h1 Signup
%form{ :action => '/signup', :method => 'post' }
  %label{ :for => 'email' }
    Email Address
  %input{ :type => 'text', :name => 'email' }
  %input{ :type => 'submit', :value => 'Signup' }


@@ login
%h1 Login
%form{ :action => '/login', :method => 'post' }
  %label{ :for => 'email' } Email Address
  %input{ :type => 'text', :name => 'email' }
  %input{ :type => 'submit', :value => 'Login' }


@@ dashboard
%h1 My Assemblies
- if @assemblies.empty?
  %p You haven't pushed any assemblies yet
- else
  %ul
    - for assembly in @assemblies
      %li
        %a{ :href => "/#{ assembly }" }= assembly
%p
  %a{ :href => '/new' } Upload Assembly


@@ upload
%h1 Upload Assembly
%form{ :action => '/', :method => 'post', :enctype => 'multipart/form-data' }
  %p
    %label{ :for => 'name' } Name
    %input{ :type => 'text', :name => 'name' }
  %p
    %label{ :for => 'version' } Version
    %input{ :type => 'text', :name => 'version' }
  %p
    %label{ :for => 'file' } Assembly
    %input{ :type => 'file', :name => 'file' }
  %input{ :type => 'submit', :value => 'Upload' }


@@ assembly
%h1= @assembly
%h2= @assembly.user
%ul
  - for version in @assembly.versions
    %li
      %a{ :href => version.path }= version


@@ version
%h1= @version
%h2= @assembly.user
%a{ :href => "#{ @version.path }.dll" } Download
%pre~ @version.attributes.to_yaml
%a{ :href => @assembly.path }= @assembly


@@ cli_results
- for assembly in @assemblies
  = assembly.name
  - if assembly.info
    = "\t" + assembly.info

@@ results
%h1= params[:q].nil? ? 'Assemblies' : 'Search Results'
%ul
  - for assembly in @assemblies
    %li
      %a{ :href => assembly.path }
        = assembly.name
      = assembly.info

@@ stylesheet

!dark      = #05112b
!light     = #0f337f
!highlight = #1a54d5

=border-radius( !size = 1em )
  :-moz-border-radius=    !size
  :-webkit-border-radius= !size

=box-shadow( !color = white )
  // right left blur color
  :-moz-box-shadow=    0.0em 0.0em 1.0em !color - #333
  :-webkit-box-shadow= 0.0em 0.0em 1.0em !color - #333

html, body
  :padding 0
  :margin  0
  :height 100%

body
  :font 14px/1.5em arial, helvetica, sans-serif
  :background-color= !dark
  :color white

  form
    :padding-left 2em

    label
      :font-size 1.5em

    input
      +border-radius(0.4em)
      :border= 1px solid !highlight
      :font-size 1.5em
      :padding 0.2em 0.5em 0.2em 0.5em

    input[type=submit]
      :font-size 1.3em

  a
    :text-decoration none
    :color white

    &:hover
      :font-weight bold

  #container
    :height 100%

    #header
      +box-shadow(black)
      :-moz-border-radius 0 0 1.5em 1.5em
      :-webkit-border-bottom-right-radius 1.5em
      :-webkit-border-bottom-left-radius  1.5em
      :padding 0 10% 0 10%
      :padding-bottom 1.5em
      :border= 1px "solid" !light
      :background-color= !light
      :width 75%
      :margin auto
      :margin-bottom 1em

      #logo
        :float left
        :font-variant small-caps

        h1
          :font-family serif
          :font-size   3.3em
          :margin-bottom 0

        h2
          :font-size 0.9em
          :padding-left 1em
          :font-style italic

      #nav
        :text-align right

        ul
          li
            :display inline
            :margin-right 1em

      #search
        :text-align right

    #content
      +border-radius(1.5em)
      +box-shadow(#000)
      :background-color white
      :color            black
      :padding          1em 1.5em 1em 1.5em
      :width 80%
      :min-height 65%
      :margin auto
      :font-size 1.4em

      a
        :color #2C44B8

      p, ul
        :margin-left 1em

      input
        :border= 1px solid !dark

  #footer
    :text-align center
    :position   absolute
    :bottom     0
    :width      100%
    :padding-bottom 0.1em
    :font-size 0.9em

    a
      :color #2C44B8
