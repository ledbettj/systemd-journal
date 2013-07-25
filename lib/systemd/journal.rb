require 'systemd/journal/native'
require 'systemd/journal/flags'
require 'systemd/journal/compat'
require 'systemd/journal_error'

module Systemd
  class Journal
    include Systemd::Journal::Compat

    # Returns a new instance of a Journal, opened with the provided options.
    # @param [Hash] opts optional initialization parameters.
    # @option opts [Integer] :flags a set of bitwise OR-ed `Journal::Flags`
    #   which control what journal files are opened.  Defaults to 0 (all).
    # @option opts [String]  :path if provided, open the journal files living
    #   in the provided directory only.  Any provided flags will be ignored per
    #   since sd_journal_open_directory does not currently accept any flags.
    def initialize(opts = {})
      flags = opts[:flags] || 0
      path  = opts[:path]
      ptr   = FFI::MemoryPointer.new(:pointer, 1)

      rc = if path
             Native::sd_journal_open_directory(ptr, path, 0)
           else
             Native::sd_journal_open(ptr, flags)
           end

      raise JournalError.new(rc) if rc < 0

      @ptr = ptr.read_pointer
      ObjectSpace.define_finalizer(self, self.class.finalize(@ptr))
    end

    # Move the read pointer to the next entry in the journal.
    # @return [Boolean] True if moving to the next entry was successful.  False
    #   indicates that we've reached the end of the journal.
    def move_next
      case (rc = Native::sd_journal_next(@ptr))
      when 0 then false # EOF
      when 1 then true
      when rc < 0 then raise JournalError.new(rc)
      end
    end

    # Move the read pointer forward by `amount` entries.
    # @return the actual number of entries which the pointer was moved by. If
    #   this number is less than the requested, we've reached the end of the
    #   journal.
    def move_next_skip(amount)
      rc = Native::sd_journal_next_skip(@ptr, amount)
      raise JournalError.new(rc) if rc < 0
      rc
    end

    # Move the read pointer to the previous entry in the journal.
    # @return [Boolean] True if moving to the previous entry was successful.
    #   False indicates that we've reached the start of the journal.
    def move_previous
      case (rc = Native::sd_journal_previous(@ptr))
      when 0 then false # EOF
      when 1 then true
      when rc < 0 then raise JournalError.new(rc)
      end
    end

    # Move the read pointer backwards by `amount` entries.
    # @return the actual number of entries which the pointer was moved by. If
    #   this number is less than the requested, we've reached the start of the
    #   journal.
    def move_previous_skip(amount)
      rc = Native::sd_journal_previous_skip(@ptr, amount)
      raise JournalError.new(rc) if rc < 0
      rc
    end

    # Seek to a position in the journal.
    # Note: after seeking, you must call move_next or move_previous before
    #   you can call read_field or current_entry
    #
    # @param [Symbol, Time] whence one of :head, :tail, or a Time instance.
    #   :head (or :start) will seek to the beginning of the journal.
    #   :tail (or :end) will seek to the end of the journal.
    #   when a Time is provided, seek to the journal entry logged closest to
    #   the provided time.
    # @return [Boolean] True on success, otherwise an error is raised.
    def seek(whence)
      rc = case whence
           when :head, :start
             Native::sd_journal_seek_head(@ptr)
           when :tail, :end
             Native::sd_journal_seek_tail(@ptr)
           when whence.is_a?(Time)
             # TODO: is this right? who knows.
             Native::sd_journal_seek_realtime_usec(@ptr, whence.to_i * 1_000_000)
           else
             raise ArgumentError.new("Unknown seek type: #{whence}")
           end

      raise JournalErrornew(rc) if rc < 0

      true
    end

    # Read the contents of the provided field from the current journal entry.
    #   move_next or move_previous must be called at least once after
    #   initialization or seeking prior to attempting to read data.
    # @param [String] field the name of the field to read -- e.g., 'MESSAGE'
    # @return [String] the value of the requested field.
    def read_field(field)
      len_ptr = FFI::MemoryPointer.new(:size_t, 1)
      out_ptr = FFI::MemoryPointer.new(:pointer, 1)

      rc = Native::sd_journal_get_data(@ptr, field, out_ptr, len_ptr)

      raise JournalError.new(rc) if rc < 0

      len = read_size_t(len_ptr)
      out_ptr.read_pointer.read_string_length(len).split('=', 2).last
    end

    # Read the contents of all fields from the current journal entry.
    # If given a block, it will yield each field in the form of
    # (fieldname, value).
    #
    # move_next or move_previous must be called at least once after
    # initialization or seeking prior to calling current_entry
    #
    # @return [Hash] the contents of the current journal entry.
    def current_entry
      Native::sd_journal_restart_data(@ptr)

      len_ptr = FFI::MemoryPointer.new(:size_t, 1)
      out_ptr = FFI::MemoryPointer.new(:pointer, 1)
      results = {}

      while
        rc = Native::sd_journal_enumerate_data(@ptr, out_ptr, len_ptr)
        raise JournalError.new(rc) if rc < 0
        break if rc == 0

        len = read_size_t(len_ptr)
        key, value = out_ptr.read_pointer.read_string_length(len).split('=', 2)
        results[key] = value

        yield(key, value) if block_given?
      end

      results
    end

    # Block until the journal is changed.
    # @param timeout_usec [Integer] the maximum number of microseconds to wait
    #   or -1 to wait indefinitely.
    def wait(timeout_usec = -1)
      rc = Native::sd_journal_wait(@ptr, timeout_usec)
      raise JournalError.new(rc) if rc < 0
    end

    # Add a filter to journal, such that only entries where the given filter
    # matches are returned.
    # move_next or move_previous must be invoked after adding a match before
    # attempting to read from the journal.
    # @param [String] field the column to filter on, e.g. _PID, _EXE.
    # @param [String] value the match to search for, e.g. '/usr/bin/sshd'
    def add_match(field, value)
      match = "#{field.to_s.upcase}=#{value}"
      rc = Native::sd_journal_add_match(@ptr, match, match.length)
      raise JournalError.new(rc) if rc < 0
    end

    # Add an OR condition to the filter.  All previously added matches
    # and any matches added afterwards will be OR-ed together.
    # move_next or move_previous must be invoked after adding a match before
    # attempting to read from the journal.
    def add_disjunction
      rc = Native::sd_journal_add_disjunction(@ptr)
      raise JournalError.new(rc) if rc < 0
    end

    # Add an AND condition to the filter.  All previously added matches
    # and any matches added afterwards will be AND-ed together.
    # move_next or move_previous must be invoked after adding a match before
    # attempting to read from the journal.
    def add_conjunction
      rc = Native::sd_journal_add_conjunction(@ptr)
      raise JournalError.new(rc) if rc < 0
    end

    # remove all matches and conjunctions/disjunctions.
    def clear_matches
      Native::sd_journal_flush_matches(@ptr)
    end

    # @return the amount of disk usage in bytes used for systemd journal
    #  files.  If Systemd::Journal::Flags::LOCAL_ONLY was passed when
    # opening the journal,  this value will only reflect the size of journal
    #files of the local host, otherwise of all hosts.
    def disk_usage
      size_ptr = FFI::MemoryPointer.new(:uint64)
      rc = Native::sd_journal_get_usage(@ptr, size_ptr)

      raise JournalError.new(rc) if rc < 0
      size_ptr.read_uint64
    end

    private

    def self.finalize(ptr)
      proc{ Native::sd_journal_close(@ptr) unless @ptr.nil? }
    end

    def read_size_t(ptr)
      case ptr.size
      when 8
        ptr.read_uint64
      when 4
        ptr.read_uint32
      else
        raise StandardError.new("Unhandled size_t size: #{ptr.size}")
      end
    end

  end
end
