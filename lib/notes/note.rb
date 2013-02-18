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
        time = '(%.3fms)' % [event.duration]
        html << <<-HTML
          #{event.ops.log_inspect.html_safe}
        HTML
        #html << <<-HTML
        #    <div>
        #      <span>[#{time}] #{event.database}['#{event.collection}'].#{event.name}(#{event.query})</span>
        #      #{event.skip.nil? ? "" : "<span>.skip(#{event.sip})</span>"}
        #      #{event.limit.nil? ? "" : "<span>.limit(#{event.limit})</span>"}
        #      #{event.order.nil? ? "" : "<span>.order(#{event.order})</span>"}
        #   </div>
        #
        #    <br>
        #HTML
      end
      html
    end
  end




  class MopedNotificationEvent < ActiveSupport::Notifications::Event
    def initialize (name, start, ending, transaction_id, payload)
      super(name, start, ending, transaction_id, payload)
    end

    def database
      payload[:database]
    end

    def collection
      payload[:collection]
    end

    def name
      payload[:name]
    end

    def query
      payload.values_at(:selector, :document, :documents, :fields ).compact.map(&:inspect).join(', ')
    end

    def skip
      payload[:skip]
    end

    def limit
      payload[:limit]
    end

    def order
      payload[:order]
    end
  end

end