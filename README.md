# Systemd::Journal [![Gem Version](https://badge.fury.io/rb/systemd-journal.png)](http://badge.fury.io/rb/systemd-journal)  [![Build Status](https://travis-ci.org/ledbettj/systemd-journal.png?branch=master)](https://travis-ci.org/ledbettj/systemd-journal) [![Code Climate](https://codeclimate.com/github/ledbettj/systemd-journal.png)](https://codeclimate.com/github/ledbettj/systemd-journal)

Ruby bindings for reading from the systemd journal.

* [gem documentation](http://rubydoc.info/gems/systemd-journal)
* [libsystemd-journal documentation](http://www.freedesktop.org/software/systemd/man/sd-journal.html)

## Installation

Add this line to your application's Gemfile:

    gem 'systemd-journal', '~> 1.1.0'

And then execute:

    bundle install

Or just `gem install systemd-journal` if you're not into that whole bundler
thing.

## Dependencies

Obviously you will need to have
[systemd](http://www.freedesktop.org/wiki/Software/systemd/) installed on your
system in order to use the gem.

__systemd 208__:

* `libsystemd-journal`
* `libsystemd-id128`

__systemd 209+__:

* `libsystemd-journal`
* `libsystemd`

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

Waiting for things to happen:

    j = Systemd::Journal.new
    j.seek(:tail)
    # wait up to one second for something to happen
    if j.wait(1_000_000)
      puts 'something changed!'
    # same as above, but can be interrupted with Control+C.
    if j.wait(1_000_000, select: true)
      puts 'something changed!'

Accessing the catalog:

    j = Systemd::Journal.new
    j.move_next
    j.move_next while !j.current_entry.catalog?

    puts j.current_entry.catalog
    # or if you have a message id:
    puts Systemd::Journal.catalog_for(j.current_entry.message_id)

See the documentation for more examples.

## Issues?

This gem has been tested primarily on Arch Linux running systemd 208.  Please
let me know if you have issues on other distributions.

If you run into problems or have questions, please open an
[Issue](https://github.com/ledbettj/systemd-journal/issues) or Pull Request.

## Pull Requests

1. Fork it
2. Create your feature branch
3. Commit your changes
4. Push to the branch
5. Create new Pull Request, targeting the __develop__ branch.
6. Wipe hands on pants, you're done!

[![Bitdeli Badge](https://d2weczhvl823v0.cloudfront.net/ledbettj/systemd-journal/trend.png)](https://bitdeli.com/free "Bitdeli Badge")
