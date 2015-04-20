# Ccs

Google XMPP GCM Server as ruby gem using Celluloid and Redis

See https://developer.android.com/google/gcm/ccs.html for more informations

## Installation

Add this line to your application's Gemfile:

    gem 'ccs', git: 'https://github.com/l3akage/ccs.git'

And then execute:

    $ bundle

## Usage

```
require 'ccs'
```

Configuration:

```
CCS.configure do |config|
  # required
  config.api_key = API_KEY
  config.sender_id = SENDER_IP
  # optional:
  config.host = 'gcm.googleapis.com'                # XMPP host
  config.port = 5235                                # XMPP port
  config.connection_count = 1                       # XMPP connection count
  config.redis_port = 6379                          # Redis port
  config.redis_host = 'localhost'                   # Redis host
  config.default_time_to_live = 600                 # time_to_live value
  config.default_delay_while_idle = true            # delay_while_idle value
  config.default_delivery_receipt_requested = true  # delivery_receipt_requested value
end
```

Delivery receipt callback

```
CCS.on_receipt do |msg|
  puts "RECEIPT: #{msg}"
end
```

Error callback

```
CCS.on_error do |msg|
  puts "ERROR: #{msg}"
end
```

Upstream callback

```
CCS.on_upstream do |msg|
  puts "UPSTREAM: #{msg}"
end
```

Logger

```
CCS.logger.level = Logger::DEBUG
```

Start connection

```
CCS.start
```

Sending data

```
CCS.send(to, data = {}, options = {})

# example

CCS.send(USER_KEY, {text: 'Hello World!'}, { time_to_live: 300, delivery_receipt_requested: true })
```

## TODO
* Tests!!!

## Contributing

1. Fork it ( https://github.com/l3akage/ccs/fork )
2. Create your feature branch (`git checkout -b my-new-feature`)
3. Commit your changes (`git commit -am 'Add some feature'`)
4. Push to the branch (`git push origin my-new-feature`)
5. Create a new Pull Request
