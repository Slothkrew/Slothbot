
require 'cinch'
require 'json'
require 'net/http'

module Slothbot

  module Plugins
		
    ##
    # A plugin that converts currencies.

    # XXX Works, could do with a cleanup and some more stringent error
    #     handling.

    class Currency

      include Cinch::Plugin
					
      match /convert \d{1,15}(\.\d{1,5})? [a-zA-Z]{3} [a-zA-Z]{3}/
      listen_to :convert, :method => :execute

			##
			# !convert <number> <currency-a> <currency-b>

			def execute(message)
				
				_, quantity, currency_a, currency_b = message.message.split /\s/
				currency_a.upcase!
				currency_b.upcase!
				quantity = quantity.to_f

				begin
					v = quantity * get_multiplier(currency_a, currency_b)
				rescue
					debug "An invalid currency was provided."
				else
					response = "#{quantity} #{currency_a} = #{v} #{currency_b}"
					@bot.channels.each { |c| Channel(c).send response }
				end
			
			end

      def get_multiplier(currency_a, currency_b)

				pair_key = "#{currency_a}_#{currency_b}"
				queries = @queries.map { |k,v| "#{k}=#{v}" }.join '&'
				queries.sub! '{currency}', pair_key
				response = Net::HTTP.get(
					"#{@fqdn}",
					"#{@resource}?#{queries}")
				
				if response.strip != '{}'
					return JSON::parse(response)[pair_key]['val']
				else
					throw Exception.new "An invalid currency was provided."
				end
			
			end

			def initialize(*)
				super
				@fqdn = 'www.freecurrencyconverterapi.com'
				@resource = '/api/v2/convert'
				@queries = { 'q' => '{currency}', 'compact' => 'y' }
			end

    end

  end

end

