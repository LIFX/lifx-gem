# LIFX

This gem allows you to control your [LIFX](http://lifx.co) lights.

It handles discovery, gateway connections, tags, and provides a object-based API
for talking to Lights.

Due to the nature of the protocol, all commands are asynchronous and will return immediately.
A synchronous version can be built on top of this gem.

This gem is in an alpha state. Expect breaking API changes.

## Installation

Add this line to your application's Gemfile:

    gem 'lifx', git: "git@github.com:LifxLabs/lifx-gem.git"

And then execute:

    $ bundle

## Usage

```ruby
client = LIFX::Client.lan                  # Talk to bulbs on the LAN
client.discover                            # Discover lights
client.lights.turn_on                      # Tell all lights to turn on
light = client.lights.with_label('Office') # Get light with label 'Office'

# Set the first light to bright green over 5 seconds
light.set_color(LIFX::Color.hsb(120, 1, 1), duration: 5)
light.set_label('My Office')

light.add_tag('Offices')   # Add tag to light

client.lights.with_tag('Offices').turn_off

client.flush # Wait until all the packets have been sent
```

## Contributing

1. Fork it
2. Create your feature branch (`git checkout -b my-new-feature`)
3. Commit your changes (`git commit -am 'Add some feature'`)
4. Push to the branch (`git push origin my-new-feature`)
5. Create new Pull Request
