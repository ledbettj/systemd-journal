require 'systemd/journal/version'
require 'systemd/journal/native'
require 'systemd/journal/flags'
require 'systemd/journal/writable'
require 'systemd/journal/fields'
require 'systemd/journal/navigable'
require 'systemd/journal/filterable'
require 'systemd/journal/waitable'
require 'systemd/journal_error'
require 'systemd/journal_entry'
require 'systemd/id128'

require 'systemd/ffi_size_t'

module Systemd
  # Class to allow interacting with the systemd journal.
  # To read from the journal, instantiate a new {Systemd::Journal}; to write to
  # the journal, use
  # {Systemd::Journal::Writable::ClassMethods#message Journal.message} or
  # {Systemd::Journal::Writable::ClassMethods#print Journal.print}.
  class Journal
    include Enumerable
    include Systemd::Journal::Writable
    include Systemd::Journal::Navigable
    include Systemd::Journal::Filterable
    include Systemd::Journal::Waitable

    # Returns a new instance of a Journal, opened with the provided options.
    # @param [Hash] opts optional initialization parameters.
    # @option opts [Integer] :flags a set of bitwise OR-ed
    #   {Systemd::Journal::Flags} which control what journal files are opened.
    #   Defaults to `0`, meaning all journals avaiable to the current user.
    # @option opts [String] :path if provided, open the journal files living
    #   in the provided directory only.  Any provided flags will be ignored
    #   since sd_journal_open_directory does not currently accept any flags.
    # @option opts [Array] :files if provided, open the provided journal files
    #   only.  Any provided flags will be ignored since sd_journal_open_files
    #   does not currently accept any flags.
    # @option opts [String] :container if provided, open the journal files from
    #   the container with the provided machine name only.
    # @example Read only system journal entries
    #   j = Systemd::Journal.new(flags: Systemd::Journal::Flags::SYSTEM_ONLY)
    # @example Directly open a journal directory
    #   j = Systemd::Journal.new(
    #     path: '/var/log/journal/5f5777e46c5f4131bd9b71cbed6b9abf'
    #   )
    def initialize(opts = {})
      validate_options!(opts)

      flags = opts[:flags] || 0
      ptr   = FFI::MemoryPointer.new(:pointer, 1)

      rc = case
           when opts[:path]
             Native.sd_journal_open_directory(ptr, opts[:path], 0)
           when opts[:files]
             Native.sd_journal_open_files(ptr, array_to_ptrs(opts[:files]), 0)
           when opts[:container]
             Native.sd_journal_open_container(ptr, opts[:container], flags)
           else
             Native.sd_journal_open(ptr, flags)
           end

      raise JournalError.new(rc) if rc < 0

      @ptr = ptr.read_pointer
      ObjectSpace.define_finalizer(self, self.class.finalize(@ptr))
    end

    # Iterate over each entry in the journal, respecting the applied
    # conjunctions/disjunctions.
    # If a block is given, it is called with each entry until no more
    # entries remain.  Otherwise, returns an enumerator which can be chained.
    def each
      return to_enum(:each) unless block_given?

      seek(:head)
      yield current_entry while move_next
    end

    # Read the contents of the provided field from the current journal entry.
    #   {#move_next} or {#move_previous} must be called at least once after
    #   initialization or seeking prior to attempting to read data.
    # @param [String] field the name of the field to read.
    # @return [String] the value of the requested field.
    # @example Read the `MESSAGE` field from the current entry
    #   j = Systemd::Journal.new
    #   j.move_next
    #   puts j.read_field('MESSAGE')
    def read_field(field)
      len_ptr = FFI::MemoryPointer.new(:size_t, 1)
      out_ptr = FFI::MemoryPointer.new(:pointer, 1)
      field   = field.to_s.upcase
      rc = Native.sd_journal_get_data(@ptr, field, out_ptr, len_ptr)

      raise JournalError.new(rc) if rc < 0

      len = len_ptr.read_size_t
      string_from_out_ptr(out_ptr, len).split('=', 2).last
    end

    # Read the contents of all fields from the current journal entry.
    # If given a block, it will yield each field in the form of
    # `(fieldname, value)`.
    #
    # {#move_next} or {#move_previous} must be called at least once after
    # initialization or seeking prior to calling {#current_entry}
    #
    # @return [Hash] the contents of the current journal entry.
    # @example Print all items in the current entry
    #   j = Systemd::Journal.new
    #   j.move_next
    #   j.current_entry{ |field, value| puts "#{field}: #{value}" }
    def current_entry
      Native.sd_journal_restart_data(@ptr)
      results = {}

      while (kvpair = enumerate_helper(:sd_journal_enumerate_data))
        key, value = kvpair
        results[key] = value
        yield(key, value) if block_given?
      end

      JournalEntry.new(results)
    end

    def current_catalog
      out_ptr = FFI::MemoryPointer.new(:pointer, 1)

      rc = Native.sd_journal_get_catalog(@ptr, out_ptr)
      raise JournalError.new(rc) if rc <  0

      Journal.read_and_free_outstr(out_ptr.read_pointer)
    end

    def self.catalog_for(message_id)
      out_ptr = FFI::MemoryPointer.new(:pointer, 1)

      rc = Native.sd_journal_get_catalog_for_message_id(
        Systemd::Id128::Native::Id128.from_s(message_id),
        out_ptr
      )
      raise JournalError.new(rc) if rc < 0

      read_and_free_outstr(out_ptr.read_pointer)
    end

    # Get the list of unique values stored in the journal for the given field.
    # If passed a block, each possible value will be yielded.
    # @return [Array] the list of possible values.
    # @example Fetch all possible boot ids from the journal
    #   j = Systemd::Journal.new
    #   j.query_unique('_BOOT_ID')
    # @example Enumerate machine IDs with a block
    #   j = Systemd::Journal.new
    #   j.query_unique('_MACHINE_ID') do |machine_id|
    #     puts "found machine id #{machine_id}"
    #   end
    def query_unique(field)
      results = []

      Native.sd_journal_restart_unique(@ptr)

      rc = Native.sd_journal_query_unique(@ptr, field.to_s.upcase)
      raise JournalError.new(rc) if rc < 0

      while (kvpair = enumerate_helper(:sd_journal_enumerate_unique))
        results << kvpair.last
      end

      results
    end

    # Get the number of bytes the Journal is currently using on disk.
    # If {Systemd::Journal::Flags::LOCAL_ONLY} was passed when opening the
    # journal,  this value will only reflect the size of journal files of the
    # local host, otherwise of all hosts.
    # @return [Integer] size in bytes
    def disk_usage
      size_ptr = FFI::MemoryPointer.new(:uint64)
      rc = Native.sd_journal_get_usage(@ptr, size_ptr)

      raise JournalError.new(rc) if rc < 0
      size_ptr.read_uint64
    end

    # Get the maximum length of a data field that will be returned.
    # Fields longer than this will be truncated.  Default is 64K.
    # @return [Integer] size in bytes.
    def data_threshold
      size_ptr = FFI::MemoryPointer.new(:size_t, 1)
      if (rc = Native.sd_journal_get_data_threshold(@ptr, size_ptr)) < 0
        raise JournalError.new(rc)
      end

      size_ptr.read_size_t
    end

    # Set the maximum length of a data field that will be returned.
    # Fields longer than this will be truncated.
    def data_threshold=(threshold)
      if (rc = Native.sd_journal_set_data_threshold(@ptr, threshold)) < 0
        raise JournalError.new(rc)
      end
    end

    private

    def array_to_ptrs(strings)
      ptr = FFI::MemoryPointer.new(:pointer, strings.length + 1)
      strings.each_with_index do |s, i|
        ptr[i].put_pointer(0, FFI::MemoryPointer.from_string(s))
      end
      ptr[strings.length].put_pointer(0, nil)
      ptr
    end

    def validate_options!(opts)
      exclusive = [:path, :files, :container]
      provided  = (opts.keys & exclusive)
      if provided.length > 1
        raise ArgumentError.new("#{provided} are conflicting options")
      end
    end

    def self.finalize(ptr)
      proc { Native.sd_journal_close(ptr) unless ptr.nil? }
    end

    def enumerate_helper(enum_function)
      len_ptr = FFI::MemoryPointer.new(:size_t, 1)
      out_ptr = FFI::MemoryPointer.new(:pointer, 1)

      rc = Native.send(enum_function, @ptr, out_ptr, len_ptr)
      raise JournalError.new(rc) if rc < 0
      return nil if rc == 0

      len = len_ptr.read_size_t
      string_from_out_ptr(out_ptr, len).split('=', 2)
    end

    def string_from_out_ptr(p, len)
      p.read_pointer.read_string_length(len)
    end

    # some sd_journal_* functions return strings that we're expected to free
    # ourselves. This function copies the string from a char* to a ruby string,
    # frees the char*, and returns the ruby string.
    def self.read_and_free_outstr(ptr)
      str = ptr.read_string
      LibC.free(ptr)
      str
    end
  end
end
