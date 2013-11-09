module Systemd
  class JournalEntry
    include Enumerable

    attr_reader :fields

    def initialize(entry)
      @entry  = entry
      @fields = entry.map do |key, value|
        name = key.downcase.to_sym
        define_singleton_method(name){ value } unless respond_to?(name)
        name
      end

    end

    def [](key)
      @entry[key] || @entry[key.to_s.upcase]
    end

    def each
      return to_enum(:each) unless block_given?

      @entry.each{ |key, value| yield [key, value] }
    end

  end
end
