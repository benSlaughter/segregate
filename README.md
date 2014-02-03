## "Data is a precious thing and will last longer than the systems themselves."

[![Code Climate](https://codeclimate.com/github/benSlaughter/segregate.png)](https://codeclimate.com/github/benSlaughter/segregate)
[![Build Status](https://travis-ci.org/benSlaughter/segregate.png?branch=master)](https://travis-ci.org/benSlaughter/segregate)
[![Dependency Status](https://gemnasium.com/benSlaughter/segregate.png)](https://gemnasium.com/benSlaughter/segregate)
[![Coverage Status](https://coveralls.io/repos/benSlaughter/segregate/badge.png?branch=master)](https://coveralls.io/r/benSlaughter/segregate?branch=master)
[![Gem Version](https://badge.fury.io/rb/segregate.png)](http://badge.fury.io/rb/segregate)

An http parser that also includes URI parsing and retaining and rebuilding the original data

---------

Segregate is an easy to use http parser, including object callback and the ability to rebuild the http message.

Segregate is designed so that it is not only incredibly easy to parse incoming data in any state, and uses URI to parse the request line path. There is also the ability to be able to manipulate and change the data and reform the message into data that can then be reused or forwarded.

### Limitations
Currently the parser is unable to handle multiple headers with the same key.

## Setup
Segregate has been tested with Ruby 1.9.2 and later.
To install:

```bash
gem install segregate
```

## Using Segregate

Require Segregate at the start of your code

```ruby
require 'segregate'
```

### Basic usage
#### Parsing data:

```ruby
parser = Segregate.new
parser.parse data
```

#### Accessing data:

```Ruby
parser.request_line
parser.request_method
parser.request_url

parser.status_line
parser.status_code
parser.status_phrase

parser.http_version
parser.major_http_version
parser.minor_http_version

parser.headers
parser.body

parser.raw_data
```

#### Modifying data:

```Ruby
parser.request_method = "POST"
parser.path = "/new/endpoint"

parser.status_code = 404
parser.status_phrase = "Not Found"

parser.http_version = [0.2]
parser.major_http_version = 3
parser.minor_http_version = 4

parser.headers.host = "www.example.com"
parser.headers['accept'] = "application/json"

parser.body.sub! "data", "information"
```

### Callback usage

```Ruby
class Callback_object
  def on_message_begin parser
  end

  def on_request_line parser
  end

  def on_status_line parser
  end

  def on_headers_complete parser
  end

  def on_body chunk
  end

  def on_body_complete parser
  end
end
```

```Ruby
parser = Segregate.new(Callback_object.new)
```

### Segregate with event machine

```Ruby
module MyHttpConnection
  def connection_completed
    @parser = Segregate.new(self)
  end

  def receive_data(data)
    @parser << data
  end

  def on_body_complete parser
    puts parser.body
  end
end
```

## Rebuilding message
### Forwarding raw data

```Ruby
socket.write parser.raw_data
```
