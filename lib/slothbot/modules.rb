
##
# Slothbot::Bot

require_relative 'currency'
require_relative 'wheel'

module Slothbot
	module Modules
		
		##
		# The base class for modules.
		#
		# TODO
		# * remove the boilerplate gunk and replace it with metaprogrammed
		#   boilerplate gunk
		# * finish off the help generating mini-framework

		class Module
			module Stateful
				def disabled
					nil
				end
				
				def enabled
					nil
				end

				def running?
					nil
				end

				def start
					nil
				end

				def stop
					nil
				end
			end

			def self.stateful
				class_exec do
					include Stateful
				end
			end

			def command?(symbol)
				@commands.include? symbol
			end

			def define_command(symbol, &block)
				@commands[symbol] = block
			end

			##
			# 100-250 characters describing the module.

			attr_accessor :description

			##
			# Modules that declare an export expose a callable meant to be called
			# by other modules.

			#def export(symbol, &block)
			#	raise NotImplementedError.new
			#end

			##
			# Modules that declare an import expect export(s) to be bound to it in
			# order to serve it. Imports may be required.

			#def import(symbol, required=false)
			#	raise NotImplementedError.new
			#end

			def initialize
				@commands = {}
				@name, @summary, @description = nil, nil, nil
			end

			def each_command(&block)
				@commands.keys.each { |command| block.call command }
			end

			##
			# TODO Decouple this to a help doc generator. For now just print it.
			#
			# Remember to raise exception if there's insufficient information
			# for a help doc.

			def help
				lines = []
			end

			attr_accessor :name

			def run_command(symbol, context, *args, &block)
				@commands[symbol].call(context, *args, &block)
			end

			def stateful?
				methods.include? :running?
			end

			##
			# 25-50 characters briefly describing the module.

			attr_accessor :summary
		end

		##
		# Currency
		# ========
		#
		# Pretty useful, but needs to be completely rewritten. Migrated old code,
		# is BAD.

		class Currency < Module
			def initialize
				super
				@converter = CurrencyConverter.new
				define_command :convert do |context, *args|
					unless args.length != 3
						begin
							quantity, c_a, c_b = args[0].to_i, args[1], args[2]
							quantity_b = @converter.convert quantity, c_a.to_sym, c_b.to_sym
							"#{quantity.to_s} #{c_a.upcase} = #{quantity_b.to_s} #{c_b.upcase}"
						rescue
							[
								"come on",
								"what the hell bro",
								"pls"
							][rand(3)]
						end
					end
				end
			end
		end

		##
		# A socket for marshalling commands to a running bot.
		#
		# BIG TODO

		class Socket < Module
			stateful

			def initialize
				@signals = {}
				#export :subscribe do |subscriber,signal|
				#	@signals[signal] = [] unless @signals.include? signal
				#	@signals[signal] << subscriber
				#end
			end
		end

		##
		# URLs
		#
		# TODO
		# ====
		#
		# It's become pretty clear that modules need a context containing some
		# optional information about the module's environment and perhaps a
		# capabilities contract delivered on initialization. For now I'll just
		# pass in the name of the user in a hash from cinch.
		#
		# * clean up the messy module code
		# * add catch alls for the commands - the bot should respond helpfully,
		#   if sarcastically
		# * add privileged users, whitelists and blacklists.
		# * add deeper methods of identifying users than their screennames
		#   (hostname, for instance, or if I can do a client cert handshake
		#   over DCC or something - that).
		# * add a sub-command framework for neatly dividing things and
		#   avoiding presenting them as methods all the time. this would
		#   really boost metaprogramming flexibility, too.
		# * add url validation and sanitization - incomplete urls should
		#   be automatically modified to be up to spec.
		# * restrict the number that will be listed. allow the use to
		#   nominate an ID range.

		class URLs < Module
			@@help = <<-eos
			 **************************************************
			 | url: url storage utility                       |
			 |------------------------------------------------|
			 | !url                     | get a random link   |
			 | !url add <url> [summary] | add a new link      |
			 | !url clear               | clear your urls     |
			 | !url latest|newest       | get the latest link |
			 | !url list [nick]         | list urls           |
			 **************************************************
			eos

			def add_url(context, *args)
				url, summary, author = args[0], args[1..-1].join(' '), context[:from]
				@registry.add_url(url, summary: summary.empty? ? nil : summary, author: author)
			end

			def clear_user_urls(context)
				@registry.delete_all_by context[:from]
			end

			def delete_url(context, *args)
				target_url = nil
				reference_url, _ = args
				@registry.each_url { |url| target_url = url if url.url == reference_url }
				if ! target_url.nil?
					if target_url.author == context[:from]
						@registry.delete_url(reference_url)
						"ok"
					else
						"im pretty sure thats #{target_url.author}'s you fascist"
					end
				else
					srand
					[
						'you need more stickers',
						'nope',
						'u crazy'
					][rand(3)]
				end
			end

			def get_help
				@@help.lines.collect { |line| line.strip }.join "\n"
			end

			def initialize(sqlite3_db_path)
				super()
				@registry = URLRegistry.new sqlite3_db_path
				define_command :url do |context, *args|
					action = args.shift
					case action
					when nil
						@registry.random.to_s
					when /^latest|newest$/
						latest_url
					when 'list'
						list_urls context, *args
					when 'clear'
						clear_user_urls context
						nil
					when 'help'
						@@help.lines.collect { |line| line.strip }.join "\n"
					when 'delete'
						delete_url context, *args
					when 'add'
						add_url context, *args
						nil
					default
						"lol wat"
					end
				end
			end

			def list_urls(context, user=nil)
				if user.nil?
					@registry.each_url.collect { |url| url.to_s }.join "\n"
				else
					list_user_urls(context, user)
				end
			end

			def list_user_urls(context, user)
				urls = @registry.each_by(user).collect { |url| url.to_s }
				urls.length > 0? urls.join("\n") : "who the shit is #{user}"
			end

			def latest_url
				@registry.latest.to_s
			end
		end

		##
		# Wheel

		class Wheel < Module
			@@help = <<-eos
			 ***********************************************
			 | wheel: best wheel utility                   |
			 |---------------------------------------------|
			 | !wheel       | fair sentence just sentence  |
			 | !wheel about | learn wheel understand wheel |
			 ***********************************************
			eos

			def initialize
				super
				@wheel = Slothbot::Wheel.new
				define_command :wheel do |context, *args|
					action = args.shift
					case action
					when nil
						@wheel.spin
					when 'about'
						"glorious wheel best wheel"
					when 'help'
						@@help.lines.collect { |line| line.strip }.join "\n"
					end
				end
			end
		end
	end
end
