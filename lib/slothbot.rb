#!/usr/bin/ruby -w

require 'cinch'

libdir = "#{File.dirname(__FILE__)}/slothbot"
ignore = []

module Slothbot
  class Bot < Cinch::Bot
  end
end

Dir.open(libdir).each do |f|
	if f[0] != '.' and ! ignore.include? f
		require_relative "#{libdir}/#{f}"
	end
end

