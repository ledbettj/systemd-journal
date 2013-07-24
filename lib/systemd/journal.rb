require 'systemd/journal/native'
require 'systemd/journal/flags'
require 'systemd/journal_error'

module Systemd
  class Journal

    def initialize(opts = {})
      flags = opts[:flags] || 0
      path  = opts[:path]
      ptr   = FFI::MemoryPointer.new(:pointer, 1)

      rc = if path
             Native::sd_journal_open_directory(ptr, path, flags)
           else
             Native::sd_journal_open(ptr, flags)
           end

      raise JournalError.new(rc) if rc < 0

      @ptr = ptr.read_pointer
      # make sure we call sd_journal_close() when we fall out of scope
      ObjectSpace.define_finalizer(self, self.class.finalize(@ptr))
    end

    def next_entry
      case (rc = Native::sd_journal_next(@ptr))
      when 0 then false # EOF
      when 1 then true
      when rc < 0 then raise JournalError.new(rc)
      end
    end

    def previous_entry
      case (rc = Native::sd_journal_previous(@ptr))
      when 0 then false # EOF
      when 1 then true
      when rc < 0 then raise JournalError.new(rc)
      end
    end

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

    def read_data(field)
      len_ptr = FFI::MemoryPointer.new(:size_t, 1)
      out_ptr = FFI::MemoryPointer.new(:pointer, 1)

      rc = Native::sd_journal_get_data(@ptr, field, out_ptr, len_ptr)

      raise JournalError.new(rc) if rc < 0

      len = read_size_t(len_ptr)
      out_ptr.read_pointer.read_string_length(len).split('=', 2).last
    end

    def enumerate_data
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

    def restart_data
      Native::sd_journal_restart_data(@ptr)
    end

    def close!
      Native::sd_journal_close(@ptr)
      @ptr = nil
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
