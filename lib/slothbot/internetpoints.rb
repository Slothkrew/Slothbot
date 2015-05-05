
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
        @from, @to, @amount, @reason, @timestamp = from, to, amount, reason, timestamp
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
      @point_model_cls = InternetPoint
      @db_path = database_path
      @db = SQLite3::Database.new @db_path
      if @db.execute("SELECT name FROM sqlite_master WHERE type='table' AND name='points'").length < 1
        @db.execute("CREATE TABLE points (timestamp INTEGER PRIMARY KEY, 'from' TEXT, 'to' TEXT, 'amount' INTEGER, 'reason' TEXT)")
      end
    end

    protected

    def unpack_row(row)
      epoch, from, to, amount, reason = row
      @point_model_cls.new(url, to: to, from: from, amount: amount, reason: reason, timestamp: Time.at(epoch))
    end
  end
end

