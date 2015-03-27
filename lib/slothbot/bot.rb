
##
# Slothbot::Bot

require_relative 'modules'

module Slothbot
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

    def run_command(symbol, context, *args, &block)
      mod = @commands[symbol][:module]
      symbol = @commands[symbol][:symbol]
      mod.run_command symbol, context, *args, &block
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
