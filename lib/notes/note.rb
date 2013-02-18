require 'moped'
module Footnotes::Notes
  class MopedSubscriber < ActiveSupport::LogSubscriber
    include Singleton
    RUNTIME_KEY = name + "#runtime"
    COUNT_KEY = name + "#count"

    def self.runtime=(value)
      Thread.current[RUNTIME_KEY] = value
    end

    def self.runtime
      Thread.current[RUNTIME_KEY] ||= 0
    end

    def self.count=(value)
      Thread.current[COUNT_KEY] = value
    end

    def self.count
      Thread.current[COUNT_KEY] ||= 0
    end

    def self.reset_runtime
      runtime
    end

    def self.events
      @@events
    end
    def self.events=(x)
      @@events=x
    end

    def initialize
      @@events = []
      super
    end

    def moped(event)
      self.class.runtime += event.duration
      self.class.count += 1
      @@events << MopedNotificationEvent.new(event.name, event.time, event.end, event.transaction_id, event.payload)
    end
    def logger
      Rails.logger
    end
    def self.reset!
      @@events.clear
    end
  end

  class MopedNote < AbstractNote
    def self.start!(controller)
      MopedSubscriber.reset!
    end

    def self.events
      MopedSubscriber.events
    end

    def self.title
      queries = MopedSubscriber.events.count
      total_time = MopedSubscriber.runtime
      "Moped Queries (#{queries}) DB (#{"%.3f" % total_time}ms)"
    end

    def content
      html = ''
      MopedSubscriber.events.each_with_index do |event, index|
        begin
          time = '(%.3fms)' % [event.duration]
          html << <<-HTML
              <div>
                <span>
                  [#{time}] #{event.database}['#{event.collection}'].#{event.command_type}(#{event.query})
                  #{event.skip > 0 ? "" : ".skip(#{event.skip})"}
                  #{event.limit < 0 ? "" : ".limit(#{event.limit})"}
                </span>
              </div>
              <br>
          HTML
        rescue Exception => e
          html << e.message
        end
      end
      html
    end
  end


  class MopedNotificationEvent < ActiveSupport::Notifications::Event
    attr_reader :database, :query, :command, :command_type, :collection, :skip, :limit
    def initialize (name, start, ending, transaction_id, payload)
      super(name, start, ending, transaction_id, {})
      message = payload[:ops].first
      @skip = message.skip.to_i
      @limit = message.limit
      @query = message.selector.inspect
      # decode it here
      if message.is_a? Moped::Protocol::Command
        @command_type = 'command'
      elsif message.is_a? Moped::Protocol::Query
        @command_type = 'find'
      elsif message.is_a? Moped::Protocol::Delete
        @command_type = 'delete'
      elsif message.is_a? Moped::Protocol::Insert
        @command_type = 'insert'
        @query = message.documents.inspect
      elsif message.is_a? Moped::Protocol::Update
        @command_type = 'update'
        @query = "(#{message.selector.inspect}), (#{message.update.inspect})"
      end

      @database = message.database
      if message.respond_to? :collection
        @collection = message.collection
      else
        @collection = "$cmd"
      end
      if @collection.eql?("$cmd") && message.selector[:count]
        @collection = message.selector[:count]
        @command_type = "count"
      end
      if message.log_inspect.include?(":mapreduce")
        @command_type = "mapreduce"
      end

    end
  end

end