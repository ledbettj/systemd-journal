require 'ffi'

# @private
class FFI::MemoryPointer

  # monkey patch a read_size_t and write_size_t method onto
  # FFI::MemoryPointer if necessary.
  case (p = FFI::MemoryPointer.new(:size_t, 1)).size
  when 4
    alias_method(:read_size_t,  :read_uint32)  unless p.respond_to?(:read_size_t)
    alias_method(:write_size_t, :write_uint32) unless p.respond_to?(:write_size_t)
  when 8
    alias_method(:read_size_t,  :read_uint64)  unless p.respond_to?(:read_size_t)
    alias_method(:write_size_t, :write_uint64) unless p.respond_to?(:write_size_t)
  else
    raise RuntimeError.new("unsupported size_t width: #{p.size}")
  end
  
end
