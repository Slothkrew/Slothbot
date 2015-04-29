
require 'sqlite3'

module Slothbot

  ##
  # A SQLite3 backed registry for storing URLs. This forms the basis for a
  # bot module for logging interesting URLs for other bored users.
  #
  # It's a nasty trainwreck of poor design. Enjoy. I might add some
  # activerecord or whatever people use later, all that matters is
  # getting all this static SQL the hell out of it.
  #
  # OTHER TODOS
  # * add an ID column / reduce the epochs so records can be deleted with
  #   id reference.

  class URLRegistry
    class URL
      attr_accessor :author

      def initialize(url, author: nil, summary: nil, timestamp: Time.now)
        @author, @summary, @timestamp, @url = author, summary, timestamp, url
      end

      attr_accessor :summary

      attr_accessor :timestamp

      def to_s
        if @summary.nil?
          "#{@url} -- #{author} (#{@timestamp.ctime})"
        else
          "#{@url} -- \"#{@summary[0..50]}\" -- #{author} (#{@timestamp.ctime})"
        end
      end

      attr_accessor :url
    end

    def <<(url_model)
      add_url url_model.url, timestamp: url_model.timestamp,
        author: url_model.author, summary: url_model.summary
    end

    def add_url(url, timestamp: Time.now, author: nil, summary: nil)
      @db.execute("INSERT INTO urls VALUES (?, ?, ?, ?)",
        [timestamp.to_i, url, author, summary])
      URL.new url, author: author, summary: summary, timestamp: timestamp
    end

    def delete_all_by(author)
      urls = @db.execute("SELECT * FROM urls WHERE (author=?)", [author]).collect { |row| unpack_row row }
      @db.execute("DELETE FROM urls WHERE (author=?)", [author]) if ! urls.empty?
      return urls
    end
    
    def count_urls
      return @db.execute("SELECT COUNT(*) FROM urls")[0][0].to_s
    end

    def count_urls_by(author)
      return @db.execute("SELECT COUNT(*) FROM urls WHERE author=?", [author])[0][0].to_s
    end

    def delete_url(url, author)
      urls = @db.execute("SELECT * FROM urls WHERE (url=? AND author=?)", [url, author]).collect { |row| unpack_row row }
      @db.execute("DELETE FROM urls WHERE (url=? AND author=?)", [url, author]) if ! urls.empty?
      return urls
    end

    def each_by(author)
      urls = []
      @db.execute("SELECT * FROM urls WHERE (author=?)", [author]) do |row|
        url = unpack_row row
        yield url if block_given?
        urls << url
      end
      return urls
    end

		def each_by_search(search)
			urls = []
			@db.execute("SELECT * FROM urls WHERE (url LIKE ? OR summary LIKE ?)", ['%' + search + '%', '%' + search + '%']) do |row|
				url = unpack_row row
				yield url if block_given?
				urls << url
			end
			return urls
		end

    def each_url
      urls = []
      @db.execute("SELECT * FROM urls") do |row|
        url = unpack_row row
        yield url if block_given?
        urls << url
      end
      return urls
    end

    def initialize(database_path, table: 'urls')
      @url_model_cls = URL
      @db_path = database_path
      @db = SQLite3::Database.new @db_path
      if @db.execute("SELECT name FROM sqlite_master WHERE type='table' AND name='urls'").length < 1
        @db.execute("CREATE TABLE urls (timestamp INTEGER PRIMARY KEY, url TEXT, author TEXT, summary TEXT)")
      end
    end

    def latest
      row = @db.execute("SELECT * FROM urls ORDER BY timestamp DESC LIMIT 1")[0]
      row.nil? ? row : unpack_row(row)
    end

    # pleasedontkillmethisisterrible

    def length
      each_url.collect { |x| x }.length
    end

    alias :newest :latest

    def oldest
      row = @db.execute("SELECT * FROM urls ORDER BY timestamp ASC LIMIT 1")[0]
      row.nil? ? row : unpack_row(row)
    end

    def random
      row = @db.execute("SELECT * FROM urls ORDER BY RANDOM() LIMIT 1")[0]
      row.nil? ? row : unpack_row(row)
    end

    def random_by(author)
      urls = each_by(author).collect { |x| x }
      if ! urls.empty?
        srand
        urls[rand(urls.length)]
      else
        nil
      end
    end

    protected

    def unpack_row(row)
      epoch, url, author, summary = row
      @url_model_cls.new(url, author: author, summary: summary, timestamp: Time.at(epoch))
    end
  end
end
