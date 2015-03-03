
##
# Slothbot::Bot

require_relative 'currency'
require_relative 'wheel'

module Slothbot
	module Modules
		
		##
		# The base class for modules.

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
			end

			def each_command(&block)
				@commands.keys.each { |command| block.call command }
			end

			def run_command(symbol, *args, &block)
				@commands[symbol].call(*args, &block)
			end

			def stateful?
				methods.include? :running?
			end
		end

		##
		# Messy PoC based on the old module. Pay no mind.

		class Currency < Module
			def initialize
				super
				@converter = CurrencyConverter.new
				define_command :convert do |*args|
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

		class Wheel < Module
			def initialize
				super
				@wheel = Slothbot::Wheel.new
				define_command :wheel do |*args|
					if args[0] == 'about' and args.length == 1
						"glorious wheel best wheel"
					else
						@wheel.spin
					end
				end
			end
		end
	end

	class Bot
		def bind_command(symbol, mod, command)
			@commands[symbol] = { :module => mod, :symbol => command }
		end

		def bound_command?(symbol)
			@commands.include? symbol
		end

		def each_command(&block)
			n_commands = 0
			@commands.keys.each do |command|
				block.call command, nil
				n_commands += 1
			end
			return n_commands
		end

		def each_module(&block)
			n_modules = 0
			@modules.each do |mod|
				block.call mod
				n_modules += 1
			end
			return n_modules
		end

		def initialize
			@commands = {}
			@modules = []
			@intended_state = :stopped
		end

		def load_module(mod)
			@modules << mod
			if mod.stateful?
				mod.enabled
				mod.start if @intended_state == :running
			end
		end

		def running?
			self.state == :running
		end
		
		# TODO Some better exception handling.

		def run_command(symbol, *args, &block)
			mod = @commands[symbol][:module]
			symbol = @commands[symbol][:symbol]
			mod.run_command symbol, *args, &block
		end

		def start
			modules_running = 0
			@intended_state = :running
			@modules.each do |mod|
				if mod.stateful?
					mod.start
					modules_running += 1
				end
			end
			@intended_state = :stopped if modules_running < 1
			return self.state
		end

		##
		# Get the bot's current run state: :running, :stopped, or :undefined.
		#
		# * :running indicates that the intended state is :running and each of the
		#   stateful modules are running.
		# * :stopped indicates that the intended state is :stopped and each of the
		#   stateful modules are stopped.
		# * :undefined indicates that the intended state and the state of each
		#   module are out of sync. This occurs when the statefulness of one or
		#   more modules has been improperly implemented or module state has
		#   been changed by other code.
		#
		# This is a flexibility measure. Modules are started and stopped as
		# appropriate when they are loaded or unloaded.

		def state
			all_running = (@modules.collect { |mod| mod.running? if mod.stateful? }).all?
			case @intended_state
			when :stopped
				all_running ? :undefined : :stopped
			when :running
				all_running ? :running : :undefined
			else
				:undefined
			end
		end
		
		def stop
			@intended_state = :stopped
			@modules.each { |mod| mod.stop if mod.stateful? }
			return self.state
		end

		def unbind_command(symbol)
			@commands.delete symbol
		end

		def unload_module(mod)
			if mod.stateful?
				mod.stop if mod.running?
				mod.disable
			end
			@modules.delete mod
		end
	end
end
