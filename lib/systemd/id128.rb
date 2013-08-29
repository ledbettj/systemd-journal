require 'ffi'

module Systemd
  module Id128

    # Get the 128-bit hex string identifying the current machine.
    # Can be used to filter a journal to show only messages originating
    # from this machine.
    # @example Filter journal to the current machine.
    #   j = Systemd::Journal.new
    #   j.add_match('_MACHINE_ID', Systemd::Id128.machine_id)
    # @return [String] 128-bit hex string representing the current machine.
    def self.machine_id
      @machine_id ||= begin
                        ptr = FFI::MemoryPointer.new(Native::Id128, 1)
                        rc = Native.sd_id128_get_machine(ptr)
                        raise JournalError.new(rc) if rc < 0
                        Native::Id128.new(ptr).to_s
                      end
    end

    # Get the 128-bit hex string identifying the current system's current boot.
    # Can be used to filter a journal to show only messages originating from
    # the current boot.
    # @example Filter journal to the current boot.
    #   j = Systemd::Journal.new
    #   j.add_match('_BOOT_ID', Systemd::Id128.boot_id)
    # @return [String] 128-bit hex string representing the current boot.
    def self.boot_id
      @boot_id ||= begin
                     ptr = FFI::MemoryPointer.new(Native::Id128, 1)
                     rc = Native.sd_id128_get_boot(ptr)
                     raise JournalError.new(rc) if rc < 0
                     Native::Id128.new(ptr).to_s
                   end
    end

    # Get a random 128-bit hex string.
    # @return [String] 128-bit random hex string.
    def self.random
      ptr = FFI::MemoryPointer.new(Native::Id128, 1)
      rc = Native.sd_id128_randomize(ptr)
      raise JournalError.new(rc) if rc < 0
      Native::Id128.new(ptr).to_s
    end

    # providing bindings to the systemd-id128 library.
    module Native
      require 'ffi'
      extend FFI::Library
      ffi_lib %w[libsystemd-id128.so libsystemd-id128.so.0]

      class Id128 < FFI::Union
        layout :bytes,  [:uint8, 16],
               :dwords, [:uint32, 4],
               :qwords, [:uint64, 2]

        def to_s
          ("%02x" * 16) % self[:bytes].to_a
        end
      end
      attach_function :sd_id128_get_machine, [:pointer], :int
      attach_function :sd_id128_get_boot,    [:pointer], :int
      attach_function :sd_id128_randomize,   [:pointer], :int
    end
  end
end
