# Systemd::Journal

Ruby bindings for reading from the systemd journal.

* [documentation](http://rubydoc.info/github/ledbettj/systemd-journal)

## Installation

Add this line to your application's Gemfile:

    gem 'systemd-journal', git: 'https://github.com/ledbettj/systemd-journal.git'

And then execute:

    $ bundle

## Usage

For example, printing all messages:

    require 'systemd/journal'
    
    j = Systemd::Journal.new
    j.seek(:head)

    while j.next_entry
      puts j.read_data('MESSAGE')
    end
    
Or to print all data in each entry:

    require 'systemd/journal'
    
    j = Systemd::Journal.new
    j.seek(:head)
    
    while j.next_entry
      j.enumerate_data do |key, value|
        puts "#{key}: #{value}"
      end
      puts "\n"
    end


## Contributing

1. Fork it
2. Create your feature branch (`git checkout -b my-new-feature`)
3. Commit your changes (`git commit -am 'Add some feature'`)
4. Push to the branch (`git push origin my-new-feature`)
5. Create new Pull Request
6. Wipe hands on pants
