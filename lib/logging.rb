# frozen_string_literal: true

# :nocov:
require 'logger'
# require 'awesome_print' # for debug output

# From http://stackoverflow.com/questions/917566/ruby-share-logger-instance-among-module-classes
module Logging
  class << self
    def logger
      @logger ||= Logger.new($stdout)
    end

    attr_writer :logger
  end

  # Addition
  def self.included(base)
    class << base
      def logger
        Logging.logger
      end
    end
  end

  def logger
    Logging.logger
  end

  def debug(debug = true)
    logger.level = if debug
                     Logger::DEBUG
                   else
                     Logger::WARN
                   end
  end
end
# :nocov:
