
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

    def get_given_by_last_day(nick)
      yesterday = Time.new - (60 * 60 * 24) #24 hours
      points_given = @db.execute("SELECT SUM(amount) FROM points WHERE [from] = ? AND timestamp > ?", [nick, yesterday.to_i]).first[0]
      points_given = 0 if points_given.nil?
      return points_given
    end

    def get_points_for(nick)
      points_taken = @db.execute("SELECT sum(amount) FROM points where [to] = ?", [nick]).first[0]
      points_taken = 0 if points_taken.nil?

      return points_taken
    end

    def add(from, to, amount, reason)

      max_points = 20
      given_last_day = get_given_by_last_day(from)
      return "Sorry, but you can't hand out more than #{max_points} points per day :(" if given_last_day >= max_points

      return "You can max hand out #{max_points - given_last_day} more points today." if given_last_day.to_i + amount.to_i > max_points    
 
      reason = '' if reason.nil?
      @db.execute("INSERT INTO points VALUES(?, ?, ?, ?, ?)", [Time.new.to_i, from, to, amount, reason])

      message = InternetPoint.new(from, to, amount, reason).to_s
      
      total_points = get_points_for to
      message += "\n#{to} now has #{total_points} magical internet points :3"
    
      return message
    end

    protected

    def unpack_row(row)
      epoch, from, to, amount, reason = row
      @point_model_cls.new(url, to: to, from: from, amount: amount, reason: reason, timestamp: Time.at(epoch))
    end
  end
end

