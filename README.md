# LIFX

[![Gem Version](https://badge.fury.io/rb/lifx.png)](https://rubygems.org/gems/lifx) [![Build Status](https://travis-ci.org/LIFX/lifx-gem.png)](https://travis-ci.org/LIFX/lifx-gem)

This gem allows you to control your [LIFX](http://lifx.co) lights.

It handles discovery, gateway connections, tags, and provides a object-based API
for talking to Lights.

Due to the nature of the current protocol, some methods are asynchronous.

This gem is in an early beta state. Expect breaking API changes.

## Requirements

* Ruby 2.0+
* Tested on OS X Mavericks, but should work other *nix platforms. Please file an issue if you have any problems.

## Installation

Add this line to your application's Gemfile:

```ruby
gem 'lifx'
```

And then execute:

```shell
$ bundle
```

Or install the gem with:

```shell
gem install lifx        # Add sudo if required.
```

## Usage

```ruby
client = LIFX::Client.lan                  # Talk to bulbs on the LAN
client.discover! do |c|                    # Discover lights. Blocks until a light with the label 'Office' is found
  c.lights.with_label('Office')
end
                                           # Blocks for a default of 10 seconds or until a light is found
client.lights.turn_on                      # Tell all lights to turn on
light = client.lights.with_label('Office') # Get light with label 'Office'

# Set the Office light to pale green over 5 seconds
green = LIFX::Color.green(saturation: 0.5)
light.set_color(green, duration: 5)        # Light#set_color is asynchronous

sleep 5                                    # Wait for light to finish changing
light.set_label('My Office')

light.add_tag('Offices')                   # Add tag to light

client.lights.with_tag('Offices').turn_off

client.flush                               # Wait until all the packets have been sent
```

## Documentation

Documentation is available at http://rubydoc.info/github/lifx/lifx-gem/master/frames. Please note that undocumented classes/methods and classes/methods marked private are not intended for public use.

LIFX uses the `HSBK` colour representation. `HSB` stands for [hue, saturation, brightness](http://en.wikipedia.org/wiki/HSV_color_space), and `K` refers to [kelvin](http://en.wikipedia.org/wiki/Color_temperature).

## Examples

Examples are located in the `examples/` folder.

* [travis-build-light](examples/travis-build-light/build-light.rb): Changes the colour of a light based on the build status of a project on Travis.
* [auto-off](examples/auto-off/auto-off.rb): Turns a light off after X seconds of it being detected turned on.
* [identify](examples/identify/identify.rb): Use divide-and-conquer search algorithm to identify a light visually.

## Useful utilities

* [lifx-console](http://github.com/chendo/lifx-console): A Pry-enabled REPL to play with LIFX easily.
* [lifx-http](http://github.com/chendo/lifx-http): A HTTP API for LIFX.

## Testing

Run with `bundle exec rspec`.

The integration specs rely on a least one device tagged with `Test` to function. At this point, they can fail occasionally due to the async nature of the protocol, and there's not much coverage at the moment as the architecture is still in flux.

A more comprehensive test suite is in the works.

## Feedback

Please file an issue for general feedback, bugs, clarification, examples, etc etc. Feel free to hit me up on Twitter, too: [@chendo](https://twitter.com/chendo).

## License

MIT. See `LICENSE.txt`
