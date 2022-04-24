# RedAmber

Simple dataframe library for Ruby

- Powered by Red Arrow
- Rover-df like simple API

## Requirements

```ruby
gem 'red-arrow',   '~> 7.0.0'
gem 'red-parquet', '~> 7.0.0' # if you use IO from/to parquet
gem 'rover-df',    '~> 0.3.0' # if you use IO from/to Rover::DataFrame
```

## Installation

Add this line to your Gemfile:

```ruby
gem 'red_amber'
```

And then execute:

    $ bundle install

Or install it yourself as:

    $ gem install red_amber

## `RedAmber::DataFrame`

### Constructors
- new from a Hash
  - `RedAmber::DataFrame.new(hash)`
- new from an Array
- new from a Rover::DataFrame
- load from a file (csv, parquet, etc.)

### Properties
- `shape`
 
  Show shape in an Array[n_rows, n_cols]
 
- `n_rows`, `nrow`, `size`, `length`
  
  Show num of rows (data size)
 
- `n_columns`, `ncols`
  
  Show num of columns (num of vectors)
 
- column_names, keys
  
  Return num of keys by an Array
 
- types
  
  Return types of columns by an Array
 
- inspect

- to_s

- lookup (not impremented)

- summary, describe (not impremented)

### Output
- to_h
- to_a
- to_rover (not impremented)
- to_csv (not impremented)
- to_parquet (not impremented)

### Selecting (not impremented)
- Selecting columns

  [key], [keys], [keys[index]]]

- Selecting rows

  head(n=5), tail(n=5), first(n=1), last(n=1)

- Selecting rows: [index], [range], [array]

### Updating (not impremented)
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

### Treat na data (not impremented)
- Drop na (NaN, nil)
- Replace na with value
- Interpolate na with convolution array

### Combining DataFrames (not impremented)
- Add rows
- Add columns
- Inner join
- Left join

### Encoding (not impremented)
- One-hot encoding

### Iteration (not impremented)

### Filtering (not impremented)


## `RedAmber::Vector`
### Constructor
- Create from columns in a DataFrame
- new from an Array

### Operations
#### Unary (not impremented)
- !, -@

#### Binary (not impremented)
- +, - , *, /, %, **
- ==, !=, >, >=, <, <=, eq, ne, gt, ge, lt, le

#### Functions (not impremented)
- abs, sum, prod, sort, sort_index
- min, max, minmax, mean, stddev, var, median, quantile
- argmin, argmax

### Updating (not impremented)


## Development

After checking out the repo, run `bin/setup` to install dependencies. Then, run `rake test-unit` to run the tests. You can also run `bin/console` for an interactive prompt that will allow you to experiment.

To install this gem onto your local machine, run `bundle exec rake install`. To release a new version, update the version number in `version.rb`, and then run `bundle exec rake release`, which will create a git tag for the version, push git commits and the created tag, and push the `.gem` file to [rubygems.org](https://rubygems.org).

## License

The gem is available as open source under the terms of the [MIT License](https://opensource.org/licenses/MIT).
