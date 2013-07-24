#!/usr/bin/env ruby

require 'systemd/journal'

if ARGV.length == 0
  puts "usage: ./#{File.basename(__FILE__)} /var/log/journal/{machine-id}"
  exit(1)
end

j = Systemd::Journal.new(path: ARGV[0])
j.seek(:head)

while j.move_next
  entry = j.current_entry
  puts "PID #{entry['_PID']}: #{entry['MESSAGE']}"
end
