# RedAmber

[![Gem Version](https://badge.fury.io/rb/red_amber.svg)](https://badge.fury.io/rb/red_amber)
[![Ruby](https://github.com/heronshoes/red_amber/actions/workflows/test.yml/badge.svg)](https://github.com/heronshoes/red_amber/actions/workflows/test.yml)

A simple dataframe library for Ruby (experimental).

- Powered by [Red Arrow](https://github.com/apache/arrow/tree/master/ruby/red-arrow) [![Gitter Chat](https://badges.gitter.im/red-data-tools/en.svg)](https://gitter.im/red-data-tools/en)
- Inspired by the dataframe library [Rover-df](https://github.com/ankane/rover)

## Requirements

```ruby
gem 'red-arrow',   '>= 8.0.0'

gem 'red-parquet', '>= 8.0.0' # Optional, if you use IO from/to parquet
gem 'rover-df',    '~> 0.3.0' # Optional, if you use IO from/to Rover::DataFrame
```

## Installation

Install requirements before you install Red Amber.

- Apache Arrow GLib (>= 8.0.0)
- Apache Parquet GLib (>= 8.0.0)

  See [Apache Arrow install document](https://arrow.apache.org/install/).
  
  Minimum installation example for the latest Ubuntu is in the ['Prepare the Apache Arrow' section in ci test](https://github.com/heronshoes/red_amber/blob/master/.github/workflows/test.yml) of Red Amber.

Add this line to your Gemfile:

```ruby
gem 'red_amber'
```

And then execute:

```shell
bundle install
```

Or install it yourself as:

```shell
gem install red_amber
```

## `RedAmber::DataFrame`

Represents a set of data in 2D-shape. The entity is a Red Arrow's Table object. 

```ruby
require 'red_amber' # require 'red-amber' is also OK.
require 'datasets-arrow'

arrow = Datasets::Penguins.new.to_arrow
RedAmber::DataFrame.new(arrow)

# =>
#<RedAmber::DataFrame : 344 x 8 Vectors, 0x0000000000013790>
    species  island    bill_length_mm bill_depth_mm flipper_length_mm ...     year
    <string> <string>        <double>      <double>           <uint8> ... <uint16>
  1 Adelie   Torgersen           39.1          18.7               181 ...     2007
  2 Adelie   Torgersen           39.5          17.4               186 ...     2007
  3 Adelie   Torgersen           40.3          18.0               195 ...     2007
  4 Adelie   Torgersen          (nil)         (nil)             (nil) ...     2007
  5 Adelie   Torgersen           36.7          19.3               193 ...     2007
  : :        :                      :             :                 : ...        :
342 Gentoo   Biscoe              50.4          15.7               222 ...     2009
343 Gentoo   Biscoe              45.2          14.8               212 ...     2009
344 Gentoo   Biscoe              49.9          16.1               213 ...     2009
```

### DataFrame model
![dataframe model of RedAmber](doc/image/dataframe_model.png)

For example, `DataFrame#pick` accepts keys as an argument and returns a sub DataFrame.

```ruby
df = penguins.pick(:body_mass_g)
df

# =>
#<RedAmber::DataFrame : 344 x 1 Vector, 0x0000000000015cc0>
    body_mass_g
       <uint16>
  1        3750
  2        3800
  3        3250
  4       (nil)
  5        3450
  :           :
342        5750
343        5200
344        5400
```

`DataFrame#assign` creates new variables (column in the table).

```ruby
df.assign(:body_mass_kg => df[:body_mass_g] / 1000.0)

# =>
#<RedAmber::DataFrame : 344 x 2 Vectors, 0x00000000000212f0>
    body_mass_g body_mass_kg
       <uint16>     <double>
  1        3750          3.8
  2        3800          3.8
  3        3250          3.3
  4       (nil)        (nil)
  5        3450          3.5
  :           :            :
342        5750          5.8
343        5200          5.2
344        5400          5.4
```

DataFrame manipulating methods like `pick`, `drop`, `slice`, `remove`, `rename` and `assign` accept a block.

This is an exaple to eliminate observations (row in the table) containing nil.

```ruby
# remove all observation contains nil
nil_removed = penguins.remove { vectors.map(&:is_nil).reduce(&:|) }
nil_removed.tdr
# =>
RedAmber::DataFrame : 342 x 8 Vectors
Vectors : 5 numeric, 3 strings
# key                type   level data_preview
1 :species           string     3 {"Adelie"=>151, "Chinstrap"=>68, "Gentoo"=>123}
2 :island            string     3 {"Torgersen"=>51, "Biscoe"=>167, "Dream"=>124}
3 :bill_length_mm    double   164 [39.1, 39.5, 40.3, 36.7, 39.3, ... ]
4 :bill_depth_mm     double    80 [18.7, 17.4, 18.0, 19.3, 20.6, ... ]
5 :flipper_length_mm int64     55 [181, 186, 195, 193, 190, ... ]
6 :body_mass_g       int64     94 [3750, 3800, 3250, 3450, 3650, ... ]
7 :sex               string     3 {"male"=>168, "female"=>165, ""=>9}
8 :year              int64      3 {2007=>109, 2008=>114, 2009=>119}
```

For this frequently needed task, we can do it much simpler.

```ruby
penguins.remove_nil # => same result as above
```

See [DataFrame.md](doc/DataFrame.md) for details.


## `RedAmber::Vector`

Class `RedAmber::Vector` represents a series of data in the DataFrame.

```ruby
penguins[:bill_length_mm]
# =>
#<RedAmber::Vector(:double, size=344):0x000000000000f8fc>
[39.1, 39.5, 40.3, nil, 36.7, 39.3, 38.9, 39.2, 34.1, 42.0, 37.8, 37.8, 41.1, ... ]
```

Vectors accepts some [functional methods from Arrow](https://arrow.apache.org/docs/cpp/compute.html).

See [Vector.md](doc/Vector.md) for details.

## Development

```shell
git clone https://github.com/heronshoes/red_amber.git
cd red_amber
bundle install
bundle exec rake test
```

## License

The gem is available as open source under the terms of the [MIT License](https://opensource.org/licenses/MIT).
