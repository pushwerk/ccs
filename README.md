# Ccs

Google XMPP GCM Server as ruby gem using Celluloid and Redis

See https://developer.android.com/google/gcm/ccs.html for more informations

## Installation

```
git clone https://github.com/l3akage/ccs.git
cd ccs && gem build ccs.gemspec
gem install ccs-*.gem
```

## Configure

Starting `ccs_server` once places a config file in `~/.config/ccs/config.yml`

### Run
Change this to `true` to make the server run

```
run: false
```

## Server ID
Not yet used (only for redis list naming)

```
server_id: 1
```

### Mode
Switch between both endpoints

```
mode: 'development'
endpoint:
  production:
    host: 'gcm-xmpp.googleapis.com'
    port: 5235
  development:
    host: 'gcm-preprod.googleapis.com'
    port: 5236
```

### Redis
Redis config

```
redis:
  host: '127.0.0.1'
  port: 6379
  # password: 'foobar' # optional
  # or
  # url: 'redis://:foobar@127.0.0.1:6379'
```

### Default values
Defaults for all messages

```
defaults:
  time_to_live: 600
  delay_while_idle: true
  delivery_receipt_requested: false
```

### Sender IDs
List of sender ids the CCS should handle. Each sender id can have up to 1000 connections

```
connections:
  - sender_id: SENDER_ID
    api_key: API_KEY
    connection_count: 10
    time_to_live: 300
  - sender_id: SENDER_ID2
    api_key: API_KEY2
    connection_count: 20
    time_to_live: 6000
    delay_while_idle: true
    delivery_receipt_requested: false
 ```

## Start server

```
ccs_server
```

## Send messages

```
require 'ccs/api'

CCS::API.send(sender_id, to, data = {}, options = {})
```

# example

```
CCS.send(SENDER_ID, USER_KEY, {text: 'Hello World!'}, { time_to_live: 300, delivery_receipt_requested: true })
```

## Handle messages

```
require 'ccs/handler'

handler = CCS::Handler.new(SENDER_ID)
handler.on_error do |msg|
  puts "ERROR: #{msg}"
end

handler.on_receipt do |msg|
  puts "RECEIPT: #{msg}"
end

handler.on_upstream do |msg|
  puts "UPSTREAM: #{msg}"
end

handler.start # start in background
handler.start! # start in foreground
```

## Logger

```
CCS.logger.level = Logger::DEBUG
```

## TODO
* TeStS !1!1

## Contributing

1. Fork it ( https://github.com/l3akage/ccs/fork )
2. Create your feature branch (`git checkout -b my-new-feature`)
3. Commit your changes (`git commit -am 'Add some feature'`)
4. Push to the branch (`git push origin my-new-feature`)
5. Create a new Pull Request
