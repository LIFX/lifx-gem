require "lifx/version"
require "bindata"
require "bindata/bool"
%w(device light sensor wan wifi message).each { |f| require "lifx/protocol/#{f}" }
require "lifx/protocol/type"
require "lifx/message"

module LIFX
  # Your code goes here...
end
