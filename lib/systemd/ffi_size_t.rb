require 'ffi'

# @private
class FFI::MemoryPointer
  # monkey patch a read_size_t and write_size_t method onto FFI::MemoryPointer
  p = FFI::MemoryPointer.new(:size_t, 1)
  w = case p.size
      when 4 then :uint32
      when 8 then :uint64
      else raise RuntimeError.new("unsupported size_t width: #{p.size}")
      end

  alias_method :read_size_t,  :"read_#{w}"  unless p.respond_to?(:read_size_t)
  alias_method :write_size_t, :"write_#{w}" unless p.respond_to?(:write_size_t)
end
