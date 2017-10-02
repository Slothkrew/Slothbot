require 'net/http'

module Slothbot
    class CyberCounter
        def count url
            resp = Net::HTTP.get url
            return resp.scan(/cyber/i).length
        end
    end
end