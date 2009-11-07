#! /usr/bin/env ruby
%w( rubygems sinatra haml sass ).each {|lib| require lib }

get '/' do
  haml :index
end

get '/styles.css' do
  content_type 'text/css'
  sass :stylesheet
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
          %h1 ASS
          %h2 The .NET Assembly Assembly Management System

        #nav
          %ul
            %li
              %a{ :href => '/' } assemblies
            %li
              %a{ :href => '/' } login
            %li
              %a{ :href => '/' } signup

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

        input
          +border-radius(0.4em)
          :border= 1px solid !highlight
          :font-size 1.5em
          :padding 0.2em 0.5em 0.2em 0.5em

        input[type=submit]
          :font-size 1.0em

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

      p, ul
        :margin-left 1em

  #footer
    :text-align center
    :position   absolute
    :bottom     0
    :width      100%
    :padding-bottom 0.1em
    :font-size 0.9em

    a
      :color #2C44B8
