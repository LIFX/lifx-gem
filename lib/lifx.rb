require "lifx/version"
require "bindata"
require "bindata_ext/bool"
require "bindata_ext/record"
%w(device light sensor wan wifi message).each { |f| require "lifx/protocol/#{f}" }

require "lifx/protocol/type"
require "lifx/message"
require "lifx/transport"

require "lifx/site"
require "lifx/network"
require "lifx/client"

require "lifx/light"

module LIFX
  # Your code goes here...
end
