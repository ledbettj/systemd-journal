module Systemd
  class JournalError < StandardError

    module LIBC
      extend FFI::Library
      ffi_lib FFI::Library::LIBC

      attach_function :strerror, [:int], :string
    end

    def initialize(code)
      super("#{-code}: #{LIBC::strerror(-code)}")
    end
  end
end
