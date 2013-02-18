require 'rails'
require 'moped_footnotes'
module MopedFootnotes
  class Railtie< Rails::Railtie
    def instrument(clazz, methods)
      clazz.module_eval do
        methods.each do |m|
          class_eval <<-CODE, __FILE__, __LINE__ + 1
            def #{m}_with_instrumentation(*args, &block)
              ActiveSupport::Notifications.instrumenter.instrument("moped.moped", {ops: args[1]}) do
                #{m}_without_instrumentation(*args, &block)
                args
              end
            end
          CODE
          alias_method_chain m, :instrumentation
        end
      end
    end
    MopedFootnotes.load!
    instrument Moped::Node,[
        :log_operations
    ]
    ActiveSupport.on_load(:action_controller) do
      include RuntimeHook
    end
    ActiveSupport::LogSubscriber.attach_to :moped, Footnotes::Notes::MopedSubscriber.instance
    Footnotes::Filter.notes += [:moped]
  end
end