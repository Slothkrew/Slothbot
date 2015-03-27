
require 'json'
require 'net/http'

##
# messy PoC based on the old module, pay no mind

module Slothbot
  class CurrencyConverter
    def convert(quantity, currency_a, currency_b)
      sloth_mode = false
      if currency_a == :sloth
        sloth_mode = :from
        currency_a = :usd
      elsif currency_b == :sloth
        sloth_mode = :to
        currency_b = :usd
      end
      c_a, c_b = currency_a.to_s.upcase, currency_b.to_s.upcase
      pair_key = "#{c_a}_#{c_b}"
      queries = @queries.map { |k,v| "#{k}=#{v}" }.join '&'
      queries.sub! '{currency}', pair_key
      response = Net::HTTP.get @fqdn, "#{@resource}?#{queries}"
      if response.strip != '{}'
        value = JSON.parse(response)[pair_key]['val'].to_f * quantity
        value = value * @sloth_multiplier if sloth_mode == :from
        value = value / @sloth_multiplier if sloth_mode == :to
        return value.round 3
      else
        throw Exception.new "An invalid currency was provided."
      end
    end

    def initialize
      @fqdn = 'www.freecurrencyconverterapi.com'
      @resource = '/api/v2/convert'
      @queries = { 'q' => '{currency}', 'compact' => 'y' }
      @sloth_multiplier = 2100
    end
  end
end
