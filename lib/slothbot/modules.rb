
##
# Slothbot::Bot

require_relative 'currency'
require_relative 'wheel'
require_relative 'cybercybercyber'

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
      # raise NotImplementedError.new
      #end

      ##
      # Modules that declare an import expect export(s) to be bound to it in
      # order to serve it. Imports may be required.

      #def import(symbol, required=false)
      # raise NotImplementedError.new
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

    class Cyber < Module
      def count url
        @cyberCounter = CyberCounter.new
        puts "url is #{url}"
        count = @CyberCounter.count url
        puts "count is #{count}"
        unless count == 0
          return "'CYBER' appears #{count} times on that page!"
        end
      end
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
            rescue# Exception  => e
              #e.inspect
              [
                "come on",
                "what the hell bro",
                "pls",
                "ya shitting me!?"
              ][rand(4)]
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
        # @signals[signal] = [] unless @signals.include? signal
        # @signals[signal] << subscriber
        #end
      end
    end

    class BusThrow < Module
      @@help = <<-eos
      ********************************
      | busthrow: slothbot best bot. |
      ********************************
      eos

      def get_help
        @@help.lines.collect { |line| line.strip }.join "\n"
      end

      def initialize
        super
        define_command :backmeup do |context, *args|
          return unless context[:from] == "sjums"
          srand
          responses = [
            "I am one hundrer percent with #{context[:from]} on this one",
            "Listen to #{context[:from]}, it's right",
            "I'm with #{context[:from]}",
            "#{context[:from]} is the cool sloth, follow the cool sloth"
          ]
          responses[rand(responses.length)]
        end
      end
    end

    ##
    # Points
    #
    # TODO
    # ====
    #
    # For starters. Make something that works.

    class Points < Module
      @@help = <<-eos
       ***************************************************************************
       | points: award each other internet points                                |
       |-------------------------------------------------------------------------|
       | !award <nick> <points> [reason] | award someone magical internet points |
       | !award about <nick>             | show who loves someone                |
       ***************************************************************************
      eos

      def get_help
        @@help.lines.collect { |line| line.strip }.join "\n"
      end

      def initialize(sqlite3_db_path)
        super()
        @registry = InternetPointsModule.new sqlite3_db_path
        define_command :award do |context, *args|
          action = args.shift
          case action
          when 'about'
            about_nick context, *args
          when 'help'
            get_help
          else
            to = action
            points = *args[0]
            reason = *args[1..-1].join(" ")
            add_award(context, to, points, reason)
          end
        end
      end

      def add_award(context, to, points, reason)
        points = points[0]
        reason = reason[0]

        return "Pls. Only positive integers ._." if (points.to_s =~ /^[0-9]+$/).nil?
        return "That's not a person in this channel!" if not context[:users].include? to.downcase
        return "You can't award yourself points, silly!" if context[:from].downcase == to.downcase
        return "C'mon man! You're supposed to GIVE points, not take them!" if points.to_i < 0

        return @registry.add(context[:from], to, points.to_i, reason)
      end

      def about_nick(context, nick)
        points_taken = @registry.get_points_for nick
        points_given = @registry.get_points_by nick

        return "#{nick} has so far recieved #{points_taken} internet points and given out #{points_given}."
      end

    end

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
       | !url find <string>       | list urls by search |
       | !url count [nick]        | you guessed it!     |
       | !url stats               | print pretty stats  |
       **************************************************
      eos

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
            "naw, mang. naw."
            #list_urls context, *args
          when /^find|search$/
            find_urls context, *args
          when 'clear'
            clear_user_urls context
            nil
          when 'count'
            count_urls context, *args
          when 'help'
            @@help.lines.collect { |line| line.strip }.join "\n"
          when 'delete'
            delete_url context, *args
          when 'add'
            add_url context, *args
            nil
          when 'stats'
            get_stats context
          else
            "lol wat"
          end
        end
      end

      def add_url(context, *args)
        url, summary, author = args[0], args[1..-1].join(' '), context[:from]
        @registry.add_url(url, summary: summary.empty? ? nil : summary, author: author)
      end

      def clear_user_urls(context)
        @registry.delete_all_by context[:from]
      end

      def count_urls(context, user=nil)
        if user.nil?
          @registry.count_urls + " delicious urls found in our collective collection"
        else
          @registry.count_urls_by(user) + " links found, added by #{user}"
        end
      end

      def get_stats(context)
        total = @registry.count_urls
        groups = @registry.count_for_authors
        oldest_url = @registry.get_oldest_url[0]

        stats_width = 40.0
        widest_name = groups.max_by do |row| row[1].length end[1].length

        outstring = " " * widest_name + " "
        outstring += "Let's see who's on top in here!\n"
        groups.each do |row|
          outstring += row[1].rjust(widest_name, ' ')
          outstring += " |"

          author_percent = (row[0].to_f / total.to_f) * 100.0
          bar_length = author_percent / (100.0 / stats_width)

          outstring += ("#" * bar_length).ljust(stats_width, ' ') + "| #{author_percent.round(2)}%\n"
        end
        outstring += " " * widest_name
        outstring += " +" + ("-" * stats_width) + "+\n"

        first_time = Time.at oldest_url.timestamp
        days_ago = (Time.now - first_time) / 60.0 / 60.0 / 24.0
        links_per_day = total.to_f / days_ago

        outstring += " " * widest_name + " "
        outstring += "Links added per day: #{links_per_day.round(2)}"

        return outstring
      end

      def delete_url(context, *args)
        target_url = nil
        reference_url, _ = args
        @registry.each_url { |url| target_url = url if url.url == reference_url }
        if ! target_url.nil?
          if target_url.author == context[:from]
            @registry.delete_url(reference_url, target_url.author)
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

      def find_urls(context, *args)
        search = args[0..-1].join(' ').to_s
        return "No." if context[:from] == "dot|not"
        return "You gotta search for something!" if search.length == 0
        urls = @registry.each_by_search(search).collect { |url| url.to_s }
        return urls.length > 0 ? urls.join("\n") : "That's a 404, bro."
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
