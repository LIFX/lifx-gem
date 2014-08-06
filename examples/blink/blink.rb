require 'bundler'
Bundler.require

lifx = LIFX::Client.lan
lifx.discover!

light = lifx.lights.first
light.set_color LIFX::Color.white, duration: 0

sleep(0.5)

light.set_color LIFX::Color.red, duration: 0

sleep(0.5)

light.set_color LIFX::Color.white, duration: 0

sleep(0.5)

light.set_color LIFX::Color.red, duration: 0