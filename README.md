# TravelTime Ruby SDK

[![Gem Version](https://badge.fury.io/rb/travel_time.svg)](https://rubygems.org/gems/travel_time)
[![GitHub Actions CI](https://github.com/traveltime-dev/traveltime-sdk-ruby/workflows/CI/badge.svg)](https://github.com/traveltime-dev/traveltime-sdk-ruby/actions?query=workflow%3ACI)


This open-source library allows you to access [TravelTime API](http://docs.traveltime.com/overview/introduction)
endpoints.

## Installation

Add this line to your application's Gemfile:

```ruby
gem 'travel_time'
```

And then execute:

    $ bundle install

Or install it yourself as:

    $ gem install travel_time

## Usage

In order to be able to call the API, you'll first need to set your Application ID and API Key:

```ruby
TravelTime.configure do |config|
  config.application_id = '<your app id>'
  config.api_key = '<your api key>'
end
```

After that, you can instantiate a client to initiate the API connection:

```ruby
client = TimeTravel::Client.new
```

You can then use the clint to call API endpoints:

```ruby
response = client.map_info
#=> #<TravelTime::Response:0x00000001452e94b0 @status=200, @headers={...}, @body={...}
```

### A note on Time

If you're calling an API endpoint that expects a time in "extended ISO-8601 format" (
e.g. `departure_searches.departure_time`), you can use the standard Ruby Time serializer:

```ruby
# This require will add the #iso8601 method to Time objects
require 'time'

departure_search = {
  id: "forward search example",
  departure_location_id: "London center",
  arrival_location_ids: ["Hyde Park", "ZSL London Zoo"],
  transportation: { type: "bus" },
  departure_time: Time.now.iso8601,
  travel_time: 1800,
  properties: ["travel_time"],
  range: { enabled: true, max_results: 3, width: 600 }
}

client.time_map(departure_searches: [departure_search])
```

## Development

After checking out the repo, run `bin/setup` to install dependencies. Then, run `rake spec` to run the tests. You can
also run `bin/console` for an interactive prompt that will allow you to experiment.

To install this gem onto your local machine, run `bundle exec rake install`.

To release a new version, update the version number in `version.rb` and then create a GitHub release. This will trigger
a GitHub Action which will push the `.gem` file to [rubygems.org](https://rubygems.org).

## Contributing

Bug reports and pull requests are welcome on GitHub at https://github.com/traveltime-dev/travel_time.

