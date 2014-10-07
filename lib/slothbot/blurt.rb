
require 'cinch'

module Slothbot

  module Plugins
		
    ##
    # A plugin that blurts out a random configured phrase every five to ten
    # minutes.

    class Blurt

      include Cinch::Plugin
        	
      match "blurt"
      listen_to :blurt, :method => :blurt

      def blurt
        if config[:phrases]
          @bot.channels.each do |channel|
            phrase = ''
            loop do
              phrase = config[:phrases][Random.rand(config[:phrases].length)]
              break if phrase != @last_phrase
						end
            @last_phrase = phrase
            Channel(channel).send(phrase)
          end
        else
          debug @@no_phrases
        end
      end

      def execute(message)
        blurt
      end

      def initialize(*)
        super
        @last_phrase = nil
        if config[:phrases]
          Thread.new do |t|
            loop do
              blurt
              sleep Random.rand(60*5) + 60*5
            end
          end
        else
          debug @@no_phrases
        end
      end

    private
      @@no_phrases = "Phrases are not configured (:phrases). Cannot blurt."

    end

  end

end

