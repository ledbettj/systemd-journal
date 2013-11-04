#!/usr/bin/env ruby
require 'systemd/journal'
require 'date'

class SSHWatcher
  def initialize
    @journal = Systemd::Journal.new(flags: Systemd::Journal::Flags::SYSTEM_ONLY)
  end

  def run
    @journal.add_match(:_exe, '/usr/bin/sshd')
    # skip all existing entries -- sd_journal_seek_tail() is currently broken.
    while @journal.move_next ; end

    @journal.watch{ |entry| process_event(entry) }
  end

  private

  LOGIN_REGEXP = /Accepted\s+(?<auth_method>[^\s]+)\s+for\s+(?<user>[^\s]+)\s+from\s+(?<address>[^\s]+)/

  def process_event(entry)
    if (m = entry.message.match(LOGIN_REGEXP))
      timestamp = DateTime.strptime(
        (entry._source_realtime_timestamp.to_i / 1_000_000).to_s,
        "%s"
      )
      puts "login via #{m[:auth_method]} for #{m[:user]} from #{m[:address]} at #{timestamp.ctime}"
    end
  end
end

SSHWatcher.new.run
