module Systemd
  class Journal
    # contains a set of constants which maybe bitwise OR-ed together and passed
    # to the Journal constructor.
    # @example
    #   Systemd::Journal.new(flags: Systemd::Journal::Flags::LOCAL_ONLY)
    module Flags
      # Only open journal files generated on the local machine.
      LOCAL_ONLY     = (1 << 0)
      # Only open non-persistent journal files.
      RUNTIME_ONLY   = (1 << 1)
      # Only open kernel and system service journal files.
      SYSTEM         = (1 << 2)
      SYSTEM_ONLY    = (1 << 2)
      # Only open current user journal files.
      CURRENT_USER   = (1 << 3)
      OS_ROOT        = (1 << 4)
      ALL_NAMESPACES = (1 << 5)
      INCLUDE_DEFAULT_NAMESPACE = (1 << 6)
    end
  end
end
