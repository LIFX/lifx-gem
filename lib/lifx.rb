require "lifx/version"
require "bindata"
require "bindata_ext/bool"
require "bindata_ext/record"

require "lifx/required_keyword_arguments"
require "lifx/utilities"
require "lifx/logging"

require "lifx/protocol/payload"
%w(device light sensor wan wifi message).each { |f| require "lifx/protocol/#{f}" }
require "lifx/protocol/type"
require "lifx/message"
require "lifx/transport"

require "lifx/config"
require "lifx/client"

module LIFX

end
