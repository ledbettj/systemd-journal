module Systemd
  class Journal
    # contains a set of constants which maybe bitwise OR-ed together and passed
    # to the Journal constructor.
    # @example
    #   Systemd::Journal.new(flags: Systemd::Journal::Flags::LOCAL_ONLY)
    module Flags
      # Only open journal files generated on the local machine.
      LOCAL_ONLY = 1 << 0
      # Only open non-persistent journal files.
      RUNTIME_ONLY = 1 << 1
      # Only open kernel and system service journal files.
      SYSTEM_ONLY = SYSTEM = 1 << 2
      CURRENT_USER = 1 << 3
      OS_ROOT = 1 << 4
      # Show all namespaces, not just the default or specified one
      ALL_NAMESPACES = 1 << 5
      # Show default namespace in addition to specified one
      INCLUDE_DEFAULT_NAMESPACE = 1 << 6
      # sd_journal_open_directory_fd() will take ownership of the provided file descriptor.
      TAKE_DIRECTORY_FD = 1 << 7
      # Assume the opened journal files are immutable. Journal entries added later may be ignored.
      ASSUME_IMMUTABLE = 1 << 8
    end
  end
end
