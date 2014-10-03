#!/usr/bin/ruby -w
#
# urlserver.rb
#
# Provides the URL shortening service used by slothbot because I hate
# commercial APIs with their heavy auth and shit. This is simple
# enough to be built on Rack and have new URLs made on the loopback
# interface while publicly serving the redirects. Apologies for the
# mess.
#

require 'rack'
require 'sqlite3'

module Slothbot

  module URLShortener

    class Database < SQLite3::Database

      def <<(url)
      end

	  	def initialize(path, bytes=3)
		  	super(path)
		  	@byte_depth = bytes > 0 and bytes <= 255 ? bytes : 3
	  	end

			def url(path)
			end

			def url?(url)
        false
			end

    end

    class Application
	
      def call(env)
        headers = {}
        if env['REQUEST_METHOD'] == 'POST' and env['PATH_INFO'] == '/'
					code = '200'
					headers['Content-Type'] = 'text/plain'
					body = ["#{@database << env['QUERY_STRING']}\r\n"]
        elsif env['REQUEST_METHOD'] == 'GET' and ! @database.url? env['PATH_INFO']
          code = '307'
          headers['Location'] == "#{@database.url env['PATH_INFO']}"
					body = []
	  		else
          code = '404'
          headers['Content-Type'] = 'text/plain'
          body = ["404 Not Found\r\n"]
				end
        [code, headers, body]
      end

      def initialize(database)
        @database = database
      end

    end

  end

end

database = Slothbot::URLShortener::Database.new 'urls.db'
Rack::Handler::WEBrick.run Slothbot::URLShortener::Application.new(database)

