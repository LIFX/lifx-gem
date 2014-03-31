# 0.4.6

- Removed Yell gem. Use stdlib Logger instead
- Broadcast IP configurable through `LIFX::Config.broadcast_ip`
- Uninitialized lights no longer shows up in `Client#lights`
- Handle Rubies that don't have IPv6 enabled

# 0.4.5

- Now supports Ruby 2.0
- Light#label can be nil
- Light#set_power and Light#set_power! now take :on and :off rather than magic number
- Use timers 1.x so no compilation is required

# 0.4.4

- Fix SO_REUSEPORT issue on older Linux kernels.

# 0.4.3

- Initial public release
