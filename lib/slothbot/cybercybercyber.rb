require 'net/http'

module Slothbot
    class CyberCounter
        def count url
            puts "counting for #{url}"
            resp = Net::HTTP.get url
            return resp.scan(/cyber/i).length
        end
    end
end