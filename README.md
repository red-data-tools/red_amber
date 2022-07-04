# RedAmber

A simple dataframe library for Ruby (experimental).

- Powered by [Red Arrow](https://github.com/apache/arrow/tree/master/ruby/red-arrow)
- Inspired by the dataframe library [Rover-df](https://github.com/ankane/rover)

## Requirements

```ruby
gem 'red-arrow',   '>= 8.0.0'
gem 'red-parquet', '>= 8.0.0' # if you use IO from/to parquet
gem 'rover-df',    '~> 0.3.0' # if you use IO from/to Rover::DataFrame
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
penguins = RedAmber::DataFrame.new(arrow)
penguins

# =>
#<RedAmber::DataFrame : 344 x 8 Vectors, 0x0000000000015144>                 
        species island  bill_length_mm  bill_depth_mm   flipper_length_mm   body_mass_g      sex     year                                                 
  0     Adelie  Torgersen            39.100000      18.700000                 181           3750     male    2007
  1     Adelie  Torgersen            39.500000      17.400000                 186           3800     female  2007
  2     Adelie  Torgersen            40.300000      18.000000                 195           3250     female  2007
  3     Adelie  Torgersen               (null)         (null)              (null)         (null)     (null)  2007
  4     Adelie  Torgersen            36.700000      19.300000                 193           3450     female  2007
  5     Adelie  Torgersen            39.300000      20.600000                 190           3650     male    2007
  6     Adelie  Torgersen            38.900000      17.800000                 181           3625     female  2007
  7     Adelie  Torgersen            39.200000      19.600000                 195           4675     male    2007
  8     Adelie  Torgersen            34.100000      18.100000                 193           3475     (null)  2007
  9     Adelie  Torgersen            42.000000      20.200000                 190           4250     (null)  2007
...
334     Gentoo  Biscoe       46.200000      14.100000                 217          4375      female  2009
335     Gentoo  Biscoe       55.100000      16.000000                 230          5850      male    2009
336     Gentoo  Biscoe       44.500000      15.700000                 217          4875      (null)  2009
337     Gentoo  Biscoe       48.800000      16.200000                 222          6000      male    2009
338     Gentoo  Biscoe       47.200000      13.700000                 214          4925      female  2009
339     Gentoo  Biscoe          (null)         (null)              (null)        (null)      (null)  2009
340     Gentoo  Biscoe       46.800000      14.300000                 215          4850      female  2009
341     Gentoo  Biscoe       50.400000      15.700000                 222          5750      male    2009
342     Gentoo  Biscoe       45.200000      14.800000                 212          5200      female  2009
343     Gentoo  Biscoe       49.900000      16.100000                 213          5400      male    2009
```

```ruby
penguins.tdr

# =>
RedAmber::DataFrame : 344 x 8 Vectors
Vectors : 5 numeric, 3 strings
# key                type   level data_preview
1 :species           string     3 {"Adelie"=>152, "Chinstrap"=>68, "Gentoo"=>124}
2 :island            string     3 {"Torgersen"=>52, "Biscoe"=>168, "Dream"=>124}
3 :bill_length_mm    double   165 [39.1, 39.5, 40.3, nil, 36.7, ... ], 2 nils
4 :bill_depth_mm     double    81 [18.7, 17.4, 18.0, nil, 19.3, ... ], 2 nils
5 :flipper_length_mm uint8     56 [181, 186, 195, nil, 193, ... ], 2 nils
6 :body_mass_g       uint16    95 [3750, 3800, 3250, nil, 3450, ... ], 2 nils
7 :sex               string     3 {"male"=>168, "female"=>165, nil=>11}
8 :year              uint16     3 {2007=>110, 2008=>114, 2009=>120}
```

### DataFrame model
![dataframe model of RedAmber](doc/image/dataframe_model.png)

For example, `DataFrame#pick` accepts keys as an argument and returns a sub DataFrame.

```ruby
df = penguins.pick(:body_mass_g)
# =>
#<RedAmber::DataFrame : 344 x 1 Vector, 0x000000000000fa14>
Vector : 1 numeric
# key          type  level data_preview
#<RedAmber::DataFrame : 344 x 1 Vector, 0x000000000002268c>
        body_mass_g
  0            3750
  1            3800
  2            3250
  3          (null)
  4            3450
  5            3650
  6            3625
  7            4675
  8            3475
  9            4250
...
334            4375
335            5850
336            4875
337            6000
338            4925
339          (null)
340            4850
341            5750
342            5200
343            5400
```

`DataFrame#assign` creates new variables (column in the table).

```ruby
df.assign(:body_mass_kg => df[:body_mass_g] / 1000.0)

# =>
#<RedAmber::DataFrame : 344 x 2 Vectors, 0x000000000002506c>
        body_mass_g     body_mass_kg
  0            3750         3.750000
  1            3800         3.800000
  2            3250         3.250000
  3          (null)           (null)
  4            3450         3.450000
  5            3650         3.650000
  6            3625         3.625000
  7            4675         4.675000
  8            3475         3.475000
  9            4250         4.250000
...
334            4375         4.375000
335            5850         5.850000
336            4875         4.875000
337            6000         6.000000
338            4925         4.925000
339          (null)           (null)
340            4850         4.850000
341            5750         5.750000
342            5200         5.200000
343            5400         5.400000
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
