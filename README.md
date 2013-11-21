# Systemd::Journal [![Gem Version](https://badge.fury.io/rb/systemd-journal.png)](http://badge.fury.io/rb/systemd-journal)  [![Build Status](https://travis-ci.org/ledbettj/systemd-journal.png?branch=master)](https://travis-ci.org/ledbettj/systemd-journal)

Ruby bindings for reading from the systemd journal.

* [gem documentation](http://rubydoc.info/gems/systemd-journal)
* [libsystemd-journal documentation](http://www.freedesktop.org/software/systemd/man/sd-journal.html)

## Installation

Add this line to your application's Gemfile:

    gem 'systemd-journal', '~> 1.0.0'

And then execute:

    bundle install

Obviously you will need to have [systemd](http://www.freedesktop.org/wiki/Software/systemd/)
installed on your system in order to use the gem.  The two native library
dependencies are `libsystemd-journal` and `libsystemd-id128`.


## Usage

    require 'systemd/journal'

Print all messages as they occur:

    j = Systemd::Journal.new
    j.seek(:tail)

    j.watch do |entry|
      puts entry.message
    end

Filter events and iterate:

    j = Systemd::Journal.new

    # only display entries from SSHD with priority 6.
    j.filter(priority: 6, _exe: '/usr/bin/sshd')
    j.each do |entry|
      puts entry.message
    end

Moving around the journal:

    j = Systemd::Journal.new

    j.seek(:head)   # move to the start of journal
    j.move(10)      # move forward by 10 entries
    c = j.cursor    # get a reference to this entry
    j.move(-5)      # move back 5 entries
    j.seek(c)       # move to the saved cursor
    j.cursor?(c)    # verify that we're at the correct entry
    j.seek(:tail)   # move to end of the journal
    j.move_previous # move back
    j.move_next     # move forward

    j.current_entry # get the entry we're currently positioned at

    # seek the entry that occured closest to this time
    j.seek(Time.parse("2013-10-31T12:00:00+04:00:00"))


See the documentation for more examples.

## Issues?

If you run into problems or have questions, please open an
[Issue](https://github.com/ledbettj/systemd-journal/issues).

## Contributing

1. Fork it
2. Create your feature branch (`git checkout -b my-new-feature`)
3. Commit your changes (`git commit -am 'Add some feature'`)
4. Push to the branch (`git push origin my-new-feature`)
5. Create new Pull Request, targeting the __develop__ branch.
6. Wipe hands on pants, you're done.
