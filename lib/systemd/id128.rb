require 'ffi'

module Systemd
  module Id128

    def self.machine_id
      @machine_id ||= begin
                        ptr = FFI::MemoryPointer.new(Native::Id128, 1)
                        rc = Native.sd_id128_get_machine(ptr)
                        raise JournalError.new(rc) if rc < 0
                        Native::Id128.new(ptr).to_s
                      end
    end

    def self.boot_id
      @boot_id ||= begin
                     ptr = FFI::MemoryPointer.new(Native::Id128, 1)
                     rc = Native.sd_id128_get_boot(ptr)
                     raise JournalError.new(rc) if rc < 0
                     Native::Id128.new(ptr).to_s
                   end
    end

    def self.random
      ptr = FFI::MemoryPointer.new(Native::Id128, 1)
      rc = Native.sd_id128_randomize(ptr)
      raise JournalError.new(rc) if rc < 0
      Native::Id128.new(ptr).to_s
    end

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
