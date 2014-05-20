### 0.4.10

- Fix `message_rate` visibility bug

### 0.4.9

- Message rate checker only runs when connection is idle
- Now uses `LIFX::TimeoutError` rather than `Timeout::Error` for internal timeout exceptions

### 0.4.8

- Routing table is only updated from State messages
- Fix memory leaks

### 0.4.7

- Only create Light devices when a Light::State is received
- Message rate checker only checks lights considered alive

### 0.4.6.1

- Fix `Time.parse` issue

### 0.4.6

- `Color#==` has been renamed to `Color#similar_to?`
- Broadcast IP configurable through `LIFX::Config.broadcast_ip`
- Removed Yell gem. Use stdlib Logger instead
- Uninitialized lights no longer shows up in `Client#lights`
- Handle Rubies that don't have IPv6 enabled

### 0.4.5

- Now supports Ruby 2.0
- Light#label can be nil
- Light#set_power and Light#set_power! now take :on and :off rather than magic number
- Use timers 1.x so no compilation is required

### 0.4.4

- Fix SO_REUSEPORT issue on older Linux kernels.

### 0.4.3

- Initial public release
