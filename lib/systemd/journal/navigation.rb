module Systemd
  class Journal
    module Navigation
      # Move the read pointer by `offset` entries.
      # @param [Integer] offset how many entries to move the read pointer by.
      #   If this value is positive, the read pointer moves forward. Otherwise,
      #   it moves backwards.
      # @return [Integer] number of entries the read pointer actually moved.
      def move(offset)
        offset > 0 ? move_next_skip(offset) : move_previous_skip(-offset)
      end

      # Move the read pointer to the next entry in the journal.
      # @return [Boolean] True if moving to the next entry was successful.
      # @return [Boolean] False if unable to move to the next entry, indicating
      #   that the pointer has reached the end of the journal.
      def move_next
        rc = Native.sd_journal_next(@ptr)
        raise JournalError.new(rc) if rc < 0
        rc > 0
      end

      # Move the read pointer forward by `amount` entries.
      # @return [Integer] actual number of entries by which the read pointer
      #   moved. If this number is less than the requested amount, the read
      #   pointer has reached the end of the journal.
      def move_next_skip(amount)
        rc = Native.sd_journal_next_skip(@ptr, amount)
        raise JournalError.new(rc) if rc < 0
        rc
      end

      # Move the read pointer to the previous entry in the journal.
      # @return [Boolean] True if moving to the previous entry was successful.
      # @return [Boolean] False if unable to move to the previous entry,
      #   indicating that the pointer has reached the beginning of the journal.
      def move_previous
        rc = Native.sd_journal_previous(@ptr)
        raise JournalError.new(rc) if rc < 0
        rc > 0
      end

      # Move the read pointer backwards by `amount` entries.
      # @return [Integer] actual number of entries by which the read pointer
      #   was moved.  If this number is less than the requested amount, the
      #   read pointer has reached the beginning of the journal.
      def move_previous_skip(amount)
        rc = Native.sd_journal_previous_skip(@ptr, amount)
        raise JournalError.new(rc) if rc < 0
        rc
      end

      # Seek to a position in the journal.
      # Note: after seeking, you must call {#move_next} or {#move_previous}
      #   before you can call {#read_field} or {#current_entry}.
      #
      # @param [Symbol, Time] whence one of :head, :tail, or a Time instance.
      #   `:head` (or `:start`) will seek to the beginning of the journal.
      #   `:tail` (or `:end`) will seek to the end of the journal. When a
      #   `Time` is provided, seek to the journal entry logged closest to that
      #   time. When a String is provided, assume it is a cursor from {#cursor}
      #   and seek to that entry.
      # @return [True]
      def seek(where)
        rc = case
             when [:head, :start].include?(where)
               Native.sd_journal_seek_head(@ptr)
             when [:tail, :end].include?(where)
               Native.sd_journal_seek_tail(@ptr)
             when where.is_a?(Time)
               Native.sd_journal_seek_realtime_usec(
                @ptr,
                where.to_i * 1_000_000
               )
             when where.is_a?(String)
               Native.sd_journal_seek_cursor(@ptr, where)
             else
               raise ArgumentError.new("Unknown seek type: #{where.class}")
             end

        raise JournalErrornew(rc) if rc < 0

        true
      end
    end
  end
end
