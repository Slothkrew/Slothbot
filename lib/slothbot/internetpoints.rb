
require 'sqlite3'

module Slothbot

  class InternetPointsModule
    class InternetPoint
      attr_accessor :from
      attr_accessor :to
      attr_accessor :amount
      attr_accessor :reason
      attr_accessor :timestamp

      def initialize(from, to, amount, reason, timestamp: Time.now)
        @from, @to, @amount, @reason, timestamp
      end

      def to_s
        if @reason.nil?
          "#{@from} gave #{@to} #{@amount} internet points (#{@timestamp.ctime})"
        else
          "#{@from} gave #{@to} #{@amount} internet points #{@reason[0..50]} (#{@timestamp.ctime})"
        end
      end
    end

    def initialize(database_path, table: 'points')
      @url_model_cls = URL
      @db_path = database_path
      @db = SQLite3::Database.new @db_path
      if @db.execute("SELECT name FROM sqlite_master WHERE type='table' AND name='points'").length < 1
        @db.execute("CREATE TABLE points (timestamp INTEGER PRIMARY KEY, url TEXT, author TEXT, summary TEXT)")
      end
    end

    protected

    def unpack_row(row)
      epoch, url, author, summary = row
      @url_model_cls.new(url, author: author, summary: summary, timestamp: Time.at(epoch))
    end
  end
end
