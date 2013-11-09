# Systemd::Journal [![Gem Version](https://badge.fury.io/rb/systemd-journal.png)](http://badge.fury.io/rb/systemd-journal)  [![Build Status](https://travis-ci.org/ledbettj/systemd-journal.png?branch=master)](https://travis-ci.org/ledbettj/systemd-journal)

Ruby bindings for reading from the systemd journal.

* [documentation](http://rubydoc.info/gems/systemd-journal)

## Installation

Add this line to your application's Gemfile:

    gem 'systemd-journal', '~> 1.0.0'

And then execute:

    bundle install

## Usage

Print all messages as they occur:

    require 'systemd/journal'
    
    j = Systemd::Journal.new
    j.seek(:tail)

    j.watch do |entry|
      puts entry.message
    end

Filter messages included in the journal:

    require 'systemd/journal'

    j = Systemd::Journal.new

    # only display entries from SSHD with priority 6.
    j.filter(priority: 6, _exe: '/usr/bin/sshd')
    j.each do |entry|
      puts entry.message
    end

See the documentation for more examples.

## Contributing

1. Fork it
2. Create your feature branch (`git checkout -b my-new-feature`)
3. Commit your changes (`git commit -am 'Add some feature'`)
4. Push to the branch (`git push origin my-new-feature`)
5. Create new Pull Request, targeting the __develop__ branch.
6. Wipe hands on pants, you're done.
