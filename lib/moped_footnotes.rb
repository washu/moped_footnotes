require 'moped'
require "moped_footnotes/version"
require 'rails-footnotes'
require 'rails-footnotes/footnotes'
require 'rails-footnotes/abstract_note'
require 'active_support/notifications'
require 'active_support/concern'

module MopedFootnotes
  def self.load!
    Dir[File.join(File.dirname(__FILE__), 'notes', '*.rb')].each { |note| require note }
  end
  require File.join(File.dirname(__FILE__), 'moped_footnotes', 'railtie') if defined?(Rails)
end
