# RedAmber

Simple dataframe library for Ruby

- Powered by Red Arrow
- Rover-df like API

## Installation

Add this line to your application's Gemfile:

```ruby
gem 'red_amber'
```

And then execute:

    $ bundle install

Or install it yourself as:

    $ gem install red_amber

## Usage

### Constructors
- new from a Hash
- new from an Array
- new from a Rover::DataFrame
- load from a file (csv, parquet, etc.)

### Properties
- shape
- size, nrows
- ncols
- keys, column_names
- types
- inspect
- to_s
- lookup
- summary, describe

### Selecting
- Selecting columns: [key], [keys], [keys[index]]]
- Selecting rows: head, tail, first(n), last(n)
- Selecting rows: [index], [range], [array]

### Updating
- Add a new column
- Update a single element
- Update multiple elements
- Update all elements
- Update elements matching a condition
- Clamp
- Delete columns
- Rename a column
- Sort rows
- Clear data

### Combining DataFrames
- Add rows
- Add columns
- Inner join
- Left join

### Encoding
- One-hot encoding

### Iteration

### Filtering

### Output
- to_a
- to_h
- to_numo
- to_rover
- to_parquet

## `Amber::Vector`
### Constructor
- new from an Array

### Operations
#### Unary
- !, -@

#### Binary
- +, - , *, /, %, **
- ==, !=, >, >=, <, <=, eq, ne, gt, ge, lt, le

#### Functions
- abs, sum, prod, sort, sort_index
- min, max, minmax, mean, stddev, var, median, quantile
- argmin, argmax

### Updating


## Development

After checking out the repo, run `bin/setup` to install dependencies. Then, run `rake test-unit` to run the tests. You can also run `bin/console` for an interactive prompt that will allow you to experiment.

To install this gem onto your local machine, run `bundle exec rake install`. To release a new version, update the version number in `version.rb`, and then run `bundle exec rake release`, which will create a git tag for the version, push git commits and the created tag, and push the `.gem` file to [rubygems.org](https://rubygems.org).

## Contributing

Bug reports and pull requests are welcome on GitHub at https://github.com/heronshoes/red_amber. This project is intended to be a safe, welcoming space for collaboration, and contributors are expected to adhere to the [code of conduct](https://github.com/heronshoes/red_amber/blob/master/CODE_OF_CONDUCT.md).

## License

The gem is available as open source under the terms of the [MIT License](https://opensource.org/licenses/MIT).

## Code of Conduct

Everyone interacting in the RedAmber project's codebases, issue trackers, chat rooms and mailing lists is expected to follow the [code of conduct](https://github.com/heronshoes/red_amber/blob/master/CODE_OF_CONDUCT.md).
