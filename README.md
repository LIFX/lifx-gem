# LIFX

This gem allows you to control your [LIFX](http://lifx.co) lights.

It handles discovery, gateway connections and rate limiting.

This gem is in an alpha state. Expect breaking API changes.

## Installation

Add this line to your application's Gemfile:

    gem 'lifx'

And then execute:

    $ bundle

Or install it yourself as:

    $ gem install lifx

## Usage

```ruby
client = LIFX::Client.new
client.discover               # Discover lights
client.lights.each do |light|
  light.set_hsb(120, 1, 1, 2) # Set all lights to bright green
end
client.flush                  # Wait until all the packets have been sent
```

## Contributing

1. Fork it
2. Create your feature branch (`git checkout -b my-new-feature`)
3. Commit your changes (`git commit -am 'Add some feature'`)
4. Push to the branch (`git push origin my-new-feature`)
5. Create new Pull Request
