module Systemd
  # Represents a single entry in the Journal.
  class JournalEntry
    include Enumerable

    attr_reader :fields

    # Create a new JournalEntry from the given entry hash. You probably don't
    # need to construct this yourself; instead instances are returned from
    # {Systemd::Journal} methods such as {Systemd::Journal#current_entry}.
    # @param [Hash] entry a hash containing all the key-value pairs associated
    #   with a given journal entry.
    def initialize(entry)
      @entry  = entry
      @fields = entry.map do |key, value|
        name = key.downcase.to_sym
        define_singleton_method(name){ value } unless respond_to?(name)
        name
      end

    end

    # Get the value of a given field in the entry, or nil if it doesn't exist
    def [](key)
      @entry[key] || @entry[key.to_s.upcase]
    end

    def each
      return to_enum(:each) unless block_given?
      @entry.each{ |key, value| yield [key, value] }
    end
  end
end
