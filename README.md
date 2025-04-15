# TravelTime Ruby SDK

[![Gem Version](https://badge.fury.io/rb/travel_time.svg)](https://rubygems.org/gems/travel_time)
[![GitHub Actions CI](https://github.com/traveltime-dev/traveltime-sdk-ruby/workflows/CI/badge.svg)](https://github.com/traveltime-dev/traveltime-sdk-ruby/actions?query=workflow%3ACI)

[Travel Time](https://docs.traveltime.com/api/overview/introduction) Ruby SDK helps users find locations by journey time rather than using ‘as the crow flies’ distance. Time-based searching gives users more opportunities for personalisation and delivers a more relevant search.

## Installation

Add this line to your application's Gemfile:

```ruby
gem 'travel_time'
```

And then execute:

```bash
$ bundle install
```

Or install it yourself as:

```bash
$ gem install travel_time
```

## Usage

In order to be able to call the API, you'll first need to set your Application ID and API Key:

```ruby
TravelTime.configure do |config|
  config.application_id = 'YOUR_APP_ID'
  config.api_key = 'YOUR_APP_KEY'
end
```

After that, you can instantiate a client to initiate the API connection:

```ruby
client = TravelTime::Client.new
```

You can then use the client to call API endpoints:

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

### Rate Limiting

You may specify an optional rate limit when initializing your client. The `rate_limit` parameter sets a cap on the number of requests that can be made to the API in 60 seconds. Requests are balanced at equal intervals.

```ruby
client = TravelTime::Client.new(rate_limit = 60)
```

### [Isochrones (Time Map)](https://docs.traveltime.com/api/reference/isochrones)
Given origin coordinates, find shapes of zones reachable within corresponding travel time.
Find unions/intersections between different searches.

Body attributes:
* departure_searches: Searches based on departure times. Leave departure location at no earlier than given time. You can define a maximum of 10 searches.
* arrival_searches: Searches based on arrival times. Arrive at destination location at no later than given time. You can define a maximum of 10 searches.
* unions: Define unions of shapes that are results of previously defined searches.
* intersections: Define intersections of shapes that are results of previously defined searches.

```ruby
require 'time'

departure_search = {
  id: "public transport from Trafalgar Square",
  coords: {
    lat: 51.506756,
    lng: -0.128050
  },
  transportation: { type: "public_transport" },
  departure_time: Time.now.iso8601,
  travel_time: 1800,
}

arrival_search = {
  id: "public transport to Trafalgar Square",
  coords: {
    lat: 51.506756,
    lng: -0.128050
  },
  transportation: { type: "public_transport" },
  arrival_time: Time.now.iso8601,
  travel_time: 1800,
  range: { enabled: true, width: 3600 }
}

union = {
  id: 'union of driving and public transport',
  search_ids: ['public transport from Trafalgar Square', 'public transport to Trafalgar Square']
}
intersection = {
  id: 'intersection of driving and public transport',
  search_ids: ['public transport from Trafalgar Square', 'public transport to Trafalgar Square']
}

response = client.time_map(
  departure_searches: [departure_search], 
  arrival_searches: [arrival_search], 
  unions: [union], 
  intersections: [intersection]
)

puts response.body
```

### [Distance Map](https://docs.traveltime.com/api/reference/distance-map)
Given origin coordinates, find shapes of zones reachable within corresponding travel distance.
Find unions/intersections between different searches.

Body attributes:
* departure_searches: Searches based on departure times. Leave departure location at no earlier than given time. You can define a maximum of 10 searches.
* arrival_searches: Searches based on arrival times. Arrive at destination location at no later than given time. You can define a maximum of 10 searches.
* unions: Define unions of shapes that are results of previously defined searches.
* intersections: Define intersections of shapes that are results of previously defined searches.

```ruby
require 'time'

departure_search = {
  id: "driving from Trafalgar Square",
  coords: {
    lat: 51.506756,
    lng: -0.128050
  },
  transportation: { type: "driving" },
  departure_time: Time.now.iso8601,
  travel_distance: 1800,
}

arrival_search = {
  id: "cycling to Trafalgar Square",
  coords: {
    lat: 51.506756,
    lng: -0.128050
  },
  transportation: { type: "cycling" },
  arrival_time: Time.now.iso8601,
  travel_distance: 1800,
  range: { enabled: true, width: 3600 }
}

union = {
  id: 'union of driving and cycling',
  search_ids: ['driving from Trafalgar Square', 'cycling to Trafalgar Square']
}

intersection = {
  id: 'intersection of driving and cycling',
  search_ids: ['driving from Trafalgar Square', 'cycling to Trafalgar Square']
}

response = client.distance_map(
  departure_searches: [departure_search], 
  arrival_searches: [arrival_search], 
  unions: [union], 
  intersections: [intersection]
)

puts response.body
```

### [Isochrones (Time Map) Fast](https://docs.traveltime.com/api/reference/isochrones-fast)
A very fast version of Isochrone API. However, the request parameters are much more limited.

```ruby
require 'time'

arrival_search = {
  id: "public transport to Trafalgar Square",
  coords: {
    lat: 51.506756,
    lng: -0.128050
  },
  transportation: { type: "public_transport" },
  arrival_time_period: 'weekday_morning',
  travel_time: 1800,
}

response = client.time_map_fast(
  arrival_searches: {
    one_to_many: [arrival_search]
  },
)

puts response.body
```

### [Distance Matrix (Time Filter)](https://docs.traveltime.com/api/reference/distance-matrix)
Given origin and destination points filter out points that cannot be reached within specified time limit.
Find out travel times, distances and costs between an origin and up to 2,000 destination points.

Body attributes:
* locations: Locations to use. Each location requires an id and lat/lng values
* departure_searches: Searches based on departure times. Leave departure location at no earlier than given time. You can define a maximum of 10 searches
* arrival_searches: Searches based on arrival times. Arrive at destination location at no later than given time. You can define a maximum of 10 searches

```ruby
require 'time'

locations = [
  {
    id: 'London center',
    coords: {
      lat: 51.508930,
      lng: -0.131387
    }
  },
  {
    id: 'Hyde Park',
    coords: {
      lat: 51.508824,
      lng: -0.167093
    }
  },
  {
    id: 'ZSL London Zoo',
    coords: {
      lat: 51.536067,
      lng: -0.153596
    }
  }
]

departure_search = {
  id: 'forward search example',
  departure_location_id: 'London center',
  arrival_location_ids: ['Hyde Park', 'ZSL London Zoo'],
  transportation: { type: 'bus' },
  departure_time: Time.now.iso8601,
  travel_time: 1800,
  properties: ['travel_time'],
  range: { enabled: true, max_results: 3, width: 600 }
}

arrival_search = {
  id: 'backward search example',
  departure_location_ids: ['Hyde Park', 'ZSL London Zoo'],
  arrival_location_id: 'London center',
  transportation: { type: 'public_transport' },
  arrival_time: Time.now.iso8601,
  travel_time: 1800,
  properties: ['travel_time', 'distance', 'distance_breakdown', 'fares']
}

response = client.time_filter(
  locations: locations, 
  departure_searches: [departure_search],
  arrival_searches: [arrival_search]
)

puts response.body
```

### [Time Filter (Fast)](https://docs.traveltime.com/api/reference/time-filter-fast)
A very fast version of `time_filter()`.
However, the request parameters are much more limited.

```ruby
locations = [
  {
    id: 'London center',
    coords: {
      lat: 51.508930,
      lng: -0.131387
    }
  },
  {
    id: 'Hyde Park',
    coords: {
      lat: 51.508824,
      lng: -0.167093
    }
  },
  {
    id: 'ZSL London Zoo',
    coords: {
      lat: 51.536067,
      lng: -0.153596
    }
  }
]

arrival_many_to_one = {
  id: 'arrive-at many-to-one search example',
  departure_location_ids: ['Hyde Park', 'ZSL London Zoo'],
  arrival_location_id: 'London center',
  transportation: { type: 'public_transport' },
  arrival_time_period: 'weekday_morning',
  travel_time: 1900,
  properties: ['travel_time', 'fares']
}

arrival_one_to_many = {
  id: 'arrive-at one-to-many search example',
  arrival_location_ids: ['Hyde Park', 'ZSL London Zoo'],
  departure_location_id: 'London center',
  transportation: { type: 'public_transport' },
  arrival_time_period: 'weekday_morning',
  travel_time: 1900,
  properties: ['travel_time', 'fares']
}

arrival_searches = {
  many_to_one: [arrival_many_to_one],
  one_to_many: [arrival_one_to_many]
}

response = client.time_filter_fast(
  locations: locations,
  arrival_searches: arrival_searches
)

puts response.body
```

### [Time Filter Fast (Proto)](https://docs.traveltime.com/api/reference/travel-time-distance-matrix-proto)
A fast version of time filter communicating using [protocol buffers](https://github.com/protocolbuffers/protobuf).

The request parameters are much more limited and only travel time is returned. In addition, the results are only approximately correct (95% of the results are guaranteed to be within 5% of the routes returned by regular time filter).

This inflexibility comes with a benefit of faster response times (Over 5x faster compared to regular time filter) and larger limits on the amount of destination points.

Body attributes:
* origin: Origin point.
* destinations: Destination points. Cannot be more than 200,000.
* country: Return the results that are within the specified country.
* transport: Transportation type.
* traveltime: Time limit.

```ruby
origin = {
  lat: 51.508930,
  lng: -0.131387,
}

destinations = [{
  lat: 51.508824,
  lng: -0.167093,
}]

response = client.time_filter_fast_proto(
  country: 'UK',
  origin: origin,
  destinations: destinations,
  transport: 'driving+ferry',
  traveltime: 7200
)
puts(response.body)
```

The responses are in the form of a list where each position denotes either a travel time (in seconds) of a journey, or if negative that the journey from the origin to the destination point is impossible.

### [Routes](https://docs.traveltime.com/api/reference/routes)
Returns routing information between source and destinations.

Body attributes:
* locations: Locations to use. Each location requires an id and lat/lng values.
* departure_searches: Searches based on departure times. Leave departure location at no earlier than given time. You can define a maximum of 10 searches.
* arrival_searches: Searches based on arrival times. Arrive at destination location at no later than given time. You can define a maximum of 10 searches.

```ruby
require 'time'

locations = [{
  id: 'London center',
  coords: {
    lat: 51.508930,
    lng: -0.131387
  }
},
{
  id: 'Hyde Park',
  coords: {
    lat: 51.508824,
    lng: -0.167093
  }
},
{
  id: 'ZSL London Zoo',
  coords: {
    lat: 51.536067,
    lng: -0.153596
  }
}]

departure_search = {
  id: 'forward search example',
  departure_location_id: 'London center',
  arrival_location_ids: ['Hyde Park', 'ZSL London Zoo'],
  transportation: {
    type: 'bus'
  },
  departure_time: Time.now.iso8601,
  travel_time: 1800,
  properties: ['travel_time'],
  range: {
    enabled: true,
    max_results: 3,
    width: 600
  }
}

arrival_search = {
  id: 'backward search example',
  departure_location_ids: ['Hyde Park', 'ZSL London Zoo'],
  arrival_location_id: 'London center',
  transportation: {
    type: 'public_transport'
  },
  arrival_time: Time.now.iso8601,
  travel_time: 1800,
  properties: ['travel_time', 'distance', 'fares', 'route']
}

response = client.routes(
  locations: locations,
  departure_searches: [departure_search],
  arrival_searches: [arrival_search]
)

puts response.body
```

### [Geocoding (Search)](https://docs.traveltime.com/api/reference/geocoding-search) 
Match a query string to geographic coordinates.

```ruby
response = client.geocoding(query: 'London', within_country: 'GB')
puts response.body
```

### [Reverse Geocoding](https://docs.traveltime.com/api/reference/geocoding-reverse)
Attempt to match a latitude, longitude pair to an address.

```ruby
response = client.reverse_geocoding(lat: 51.506756, lng: -0.128050)
puts response.body
```

### [Time Filter (Postcodes)](https://docs.traveltime.com/api/reference/postcode-search)
Find reachable postcodes from origin (or to destination) and get statistics about such postcodes.
Currently only supports United Kingdom.

```ruby
require 'time'

departure_search = {
  id: 'public transport from Trafalgar Square',
  departure_time: Time.now.iso8601,
  travel_time: 1800,
  coords: { lat: 51.507609, lng: -0.128315 },
  transportation: { type: 'public_transport' },
  properties: ['travel_time', 'distance']
}

arrival_search = {
  id: 'public transport to Trafalgar Square',
  arrival_time: Time.now.iso8601,
  travel_time: 1800,
  coords: { lat: 51.507609, lng: -0.128315 },
  transportation: { type: 'public_transport' },
  properties: ['travel_time', 'distance']
}

response = client.time_filter_postcodes(
  departure_searches: [departure_search], 
  arrival_searches: [arrival_search]
)

puts response.body
```

### [Time Filter (Postcode Districts)](https://docs.traveltime.com/api/reference/postcode-district-filter)
Find districts that have a certain coverage from origin (or to destination) and get statistics about postcodes within such districts.
Currently only supports United Kingdom.

```ruby
require 'time'

departure_search = {
  id: 'public transport from Trafalgar Square',
  departure_time: Time.now.iso8601,
  travel_time: 1800,
  coords: { lat: 51.507609, lng: -0.128315 },
  transportation: { type: 'public_transport' },
  properties: ['coverage', 'travel_time_reachable', 'travel_time_all'],
  reachable_postcodes_threshold: 0.1
}

arrival_search = {
  id: 'public transport to Trafalgar Square',
  arrival_time: Time.now.iso8601,
  travel_time: 1800,
  coords: { lat: 51.507609, lng: -0.128315 },
  transportation: { type: 'public_transport' },
  properties: ['coverage', 'travel_time_reachable', 'travel_time_all'],
  reachable_postcodes_threshold: 0.1
}

response = client.time_filter_postcode_districts(
  departure_searches: [departure_search],
  arrival_searches: [arrival_search]
)

puts response.body
```

### [Time Filter (Postcode Sectors)](https://docs.traveltime.com/api/reference/postcode-sector-filter)
Find sectors that have a certain coverage from origin (or to destination) and get statistics about postcodes within such sectors.
Currently only supports United Kingdom.

```ruby
require 'time'

departure_search = {
  id: 'public transport from Trafalgar Square',
  departure_time: Time.now.iso8601,
  travel_time: 1800,
  coords: { lat: 51.507609, lng: -0.128315 },
  transportation: { type: 'public_transport' },
  properties: ['coverage', 'travel_time_reachable', 'travel_time_all'],
  reachable_postcodes_threshold: 0.1
}

arrival_search = {
  id: 'public transport to Trafalgar Square',
  arrival_time: Time.now.iso8601,
  travel_time: 1800,
  coords: { lat: 51.507609, lng: -0.128315 },
  transportation: { type: 'public_transport' },
  properties: ['coverage', 'travel_time_reachable', 'travel_time_all'],
  reachable_postcodes_threshold: 0.1
}

response = client.time_filter_postcode_sectors(
  departure_searches: [departure_search],
  arrival_searches: [arrival_search]
)

puts response.body
```

### [Map Info](https://docs.traveltime.com/api/reference/map-info)
Get information about currently supported countries.

```ruby
response = client.map_info
puts response.body
```

### [Supported Locations](https://docs.traveltime.com/api/reference/supported-locations)
Find out what points are supported by the api.

```ruby
locations = [{
  id: "London",
  coords: {
    lat: 51.506756,
    lng: -0.128050
  }
},
{
  id: "Bangkok",
  coords: {
    lat: 13.761866,
    lng: 100.544818
  }
},
{
  id: "Lisbon",
  coords: {
    lat: 38.721869,
    lng: -9.138549
  }
},
{
  id: "Kaunas",
  coords: {
    lat: 54.900008,
    lng: 23.957734
  }
}]

response = client.supported_locations(locations: locations)

puts response.body
```

## Development

### Set up Ruby Version Manager

This is optional, but enables you not installing gems to system directories.

1. Install RVM: https://rvm.io/
2. Optional gnome-terminal integration: https://rvm.io/integration/gnome-terminal
3. Install and set up Ruby with RVM:
```shell
rvm install ruby-3.2.2
rvm alias create default ruby-3.2.2
rvm use ruby-3.2.2
rvm gemset create traveltime-sdk
```

### Start using RVM

```shell
rvm use default@traveltime-sdk
```

### Install dependencies

Run `bin/setup` to install dependencies.

### Run tests

Run `rake spec` to run the tests.

### Interactive prompt

Run `bin/console` for an interactive prompt that will allow you to experiment.

### Installing TravelTime gem

To install this gem onto your local machine, run `bundle exec rake install`.

### Updating proto files

Ruby proto files are currently generated manually and pushed to the repo.

If `.proto` files were changed, you can generate Ruby code like this:

```bash
# For example, if current dir = lib/travel_time/proto
protoc --proto_path=source --ruby_out=v2 source/*.proto

# After the generation, modify files that import `RequestsCommon` to use `require_relative` instead of `require`.
# This command can be used
find v2 -name "*_pb.rb" -exec sed -i 's/require \x27\(.*_pb\)\x27/require_relative \x27\1\x27/g' {} \;
```

This comment sums up the current open PRs and Issues on the `require` vs `require_relative` topic:
https://github.com/grpc/grpc/issues/29027#issuecomment-1963075200

Other solution could be using `ruby-protobuf` plugin (https://github.com/ruby-protobuf/protobuf/pull/377), but that
might require a larger rework.

### Release

To release a new version, update the version number in `version.rb` and then create a GitHub release. This will trigger
a GitHub Action which will push the `.gem` file to [rubygems.org](https://rubygems.org).

## Contributing

Bug reports and pull requests are welcome on GitHub at https://github.com/traveltime-dev/traveltime-sdk-ruby.
