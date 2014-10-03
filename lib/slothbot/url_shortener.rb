
require 'cinch'
require 'net/http'

module Slothbot

  module Plugins

    ##
    # Uses a self-hosted URL shortening service to do exactly as
    # advertised.

    class URLShortener

      include Cinch::Plugin

      match 'shorten'

      def shorten(msg)
        # TODO check the command is being invoked from a PM context
        # TODO split url from target channel
        if config[:uri]
          # TODO feed the request to the URL shortener and print the result
        end
			end

    end

  end

end

