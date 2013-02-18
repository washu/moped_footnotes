module MopedFootnotes
  module RuntimeHook
    extend ActiveSupport::Concern

    protected
    attr_internal :moped_runtime
    def process_action(action, *args)
      Footnotes::Notes::MopedSubscriber.reset_runtime
      super
    end

    def cleanup_view_runtime
      moped_rt_before_render = Footnotes::Notes::MopedSubscriber.reset_runtime
      runtime = super
      moped_rt_after_render = Footnotes::Notes::MopedSubscriber.reset_runtime
      self.moped_runtime = mongo_rt_before_render + moped_rt_after_render
      runtime - moped_rt_after_render
    end
  end
end