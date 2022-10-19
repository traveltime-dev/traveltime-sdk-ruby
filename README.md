# TravelTime Ruby SDK

[![Gem Version](https://badge.fury.io/rb/travel_time.svg)](https://rubygems.org/gems/travel_time)
[![GitHub Actions CI](https://github.com/traveltime-dev/traveltime-sdk-ruby/workflows/CI/badge.svg)](https://github.com/traveltime-dev/traveltime-sdk-ruby/actions?query=workflow%3ACI)


This open-source library allows you to access [TravelTime API](https://docs.traveltime.com/overview/introduction)
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
client = TravelTime::Client.new
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


### [Isochrones (Time Map)](https://traveltime.com/docs/api/reference/isochrones)
Given origin coordinates, find shapes of zones reachable within corresponding travel time.
Find unions/intersections between different searches.

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

### [Distance Matrix (Time Filter)](https://traveltime.com/docs/api/reference/distance-matrix)
Given origin and destination points filter out points that cannot be reached within specified time limit.
Find out travel times, distances and costs between an origin and up to 2,000 destination points.

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

### [Routes](https://traveltime.com/docs/api/reference/routes)
Returns routing information between source and destinations.

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

### [Time Filter (Fast)](https://traveltime.com/docs/api/reference/time-filter-fast)
A very fast version of time_filter().
However, the request parameters are much more limited.
Currently only supports UK and Ireland.

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

### [Time Filter (Postcode Districts)](https://traveltime.com/docs/api/reference/postcode-district-filter)
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

### [Time Filter (Postcode Sectors)](https://traveltime.com/docs/api/reference/postcode-sector-filter)
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

### [Time Filter (Postcodes)](https://traveltime.com/docs/api/reference/postcode-search)
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

### [Geocoding (Search)](https://traveltime.com/docs/api/reference/geocoding-search) 
Match a query string to geographic coordinates.

```ruby
response = client.geocoding(query: 'London', within_country: 'GB')
puts response.body
```

### [Reverse Geocoding](https://traveltime.com/docs/api/reference/geocoding-reverse)
Attempt to match a latitude, longitude pair to an address.

```ruby
response = client.reverse_geocoding(lat: 51.506756, lng: -0.128050)
puts response.body
```

### [Map Info](https://traveltime.com/docs/api/reference/map-info)
Get information about currently supported countries.

```ruby
response = client.map_info
puts response.body
```

### [Supported Locations](https://traveltime.com/docs/api/reference/supported-locations)
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

After checking out the repo, run `bin/setup` to install dependencies. Then, run `rake spec` to run the tests. You can
also run `bin/console` for an interactive prompt that will allow you to experiment.

To install this gem onto your local machine, run `bundle exec rake install`.

To release a new version, update the version number in `version.rb` and then create a GitHub release. This will trigger
a GitHub Action which will push the `.gem` file to [rubygems.org](https://rubygems.org).

## Contributing

Bug reports and pull requests are welcome on GitHub at https://github.com/traveltime-dev/travel_time.