#!/usr/bin/ruby -w
#
# Slothbot
#

require_relative 'lib/slothbot'

server  = 'chat.freenode.net'
channel = '#slothkrew'
nick    = 'slothbot'

ARGV.each_with_index do |arg, i|
  arg == '-s' ? server = ARGV[i+1] : server
  arg == '-c' ? channel = "##{ARGV[i+1]}" : channel
  arg == '-n' ? nick = ARGV[i+1] : nick
end

slothbot = Slothbot::Bot.new do
  configure do |c|
    c.nick = nick
    c.user = nick
    c.server = server
    c.port = 6697
    c.ssl.use = true
    c.channels = [channel]
    c.plugins.plugins = []
  end
end
slothbot.start

