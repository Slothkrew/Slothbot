require 'cinch'
require 'net/http'

module Slothbot
  module Plugins

    ##
    # Uses a self-hosted URL shortening service to do exactly as
    # advertised.

    class URLShortener
      include Cinch::Plugin

      listen_to :private
      match 'shorten'

      def shorten(msg)
        # TODO split url from target channel
        if config[:uri]
          # TODO feed the request to the URL shortener and print the result
        end
			end

    end

  end

end

