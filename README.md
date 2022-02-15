# TravelTime Ruby SDK

This open-source library allows you to access [TravelTime API](http://docs.traveltime.com/overview/introduction) endpoints.

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
#=> 
```

## Development

After checking out the repo, run `bin/setup` to install dependencies. Then, run `rake spec` to run the tests. You can also run `bin/console` for an interactive prompt that will allow you to experiment.

To install this gem onto your local machine, run `bundle exec rake install`.

To release a new version, update the version number in `version.rb` and then create a GitHub release.
This will trigger a GitHub Action which will push the `.gem` file to [rubygems.org](https://rubygems.org).

## Contributing

Bug reports and pull requests are welcome on GitHub at https://github.com/traveltime-dev/travel_time.

