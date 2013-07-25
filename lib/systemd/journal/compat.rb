require 'systemd/journal/native'
require 'systemd/journal_error'

module Systemd
  class Journal
    # This module provides compatibility with the systemd-journal.gem
    # by Daniel Mack (https://github.com/zonque/systemd-journal.gem)
    module Compat

      LOG_EMERG   = 0 # system is unusable
      LOG_ALERT   = 1 # action must be taken immediately
      LOG_CRIT    = 2 # critical conditions
      LOG_ERR     = 3 # error conditions
      LOG_WARNING = 4 # warning conditions
      LOG_NOTICE  = 5 # normal but significant condition
      LOG_INFO    = 6 # informational
      LOG_DEBUG   = 7 # debug-level messages

      def self.included(base)
        base.extend(ClassMethods)
      end

      module ClassMethods

        # write a simple message to the systemd journal.
        # @param [Integer] level one of the LOG_* constants defining the
        #   severity of the event.
        # @param [String] message the content of the message to write.
        def print(level, message)
          rc = Native::sd_journal_print(level, message)
          raise JournalError.new(rc) if rc < 0
        end

        # write an event to the systemd journal.
        # @param [Hash] contents the set of key-value pairs defining the event.
        def message(contents)
          items = contents.flat_map do |k,v|
            [:string, "#{k.to_s.upcase}=#{v}"]
          end
          # add a null pointer to terminate the varargs
          items += [:string, nil]
          rc = Native::sd_journal_send(*items)
          raise JournalError.new(rc) if rc < 0
        end
      end

    end
  end
end
