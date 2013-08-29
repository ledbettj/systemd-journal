# Systemd::Journal

Ruby bindings for reading from the systemd journal.

* [documentation](http://rubydoc.info/github/ledbettj/systemd-journal/Systemd/Journal)

## Installation

Add this line to your application's Gemfile:

    gem 'systemd-journal', '~> 0.1.0'

And then execute:

    bundle install

## Usage

For example, printing all messages:

    require 'systemd/journal'
    
    j = Systemd::Journal.new
    
    while j.move_next
      puts j.read_field('MESSAGE')
    end
    
Or to print all data in each entry:

    require 'systemd/journal'
    
    j = Systemd::Journal.new
    
    while j.move_next
      j.current_entry do |key, value|
        puts "#{key}: #{value}"
      end
      puts "\n"
    end

## Contributing

1. Fork it
2. Create your feature branch (`git checkout -b my-new-feature`)
3. Commit your changes (`git commit -am 'Add some feature'`)
4. Push to the branch (`git push origin my-new-feature`)
5. Create new Pull Request, targeting the __develop__ branch.
6. Wipe hands on pants, you're done.
