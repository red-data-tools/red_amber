# RedAmber

A simple dataframe library for Ruby (experimental)

- Powered by [Red Arrow](https://github.com/apache/arrow/tree/master/ruby/red-arrow)
- Simple API similar to [Rover-df](https://github.com/ankane/rover)

## Requirements

```ruby
gem 'red-arrow',   '>= 8.0.0'
gem 'red-parquet', '>= 8.0.0' # if you use IO from/to parquet
gem 'rover-df',    '~> 0.3.0' # if you use IO from/to Rover::DataFrame
```

## Installation

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

Represents a set of data in 2D-shape.

```ruby
require 'red_amber'
require 'datasets-arrow'

penguins = Datasets::Penguins.new.to_arrow
puts RedAmber::DataFrame.new(penguins).tdr
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
1 :body_mass_g int64    95 [3750, 3800, 3250, nil, 3450, ... ], 2 nils
```

`DataFrame#assign` creates new variable (column in table).

```ruby
df.assign(:body_mass_kg => df[:body_mass_g] / 1000.0)
end
# =>
#<RedAmber::DataFrame : 344 x 2 Vectors, 0x000000000000fa28>
Vectors : 2 numeric
# key           type   level data_preview
1 :body_mass_g  int64     95 [3750, 3800, 3250, nil, 3450, ... ], 2 nils
2 :body_mass_kg double    95 [3.75, 3.8, 3.25, nil, 3.45, ... ], 2 nils
```

DataFrame manipulating methods like `pick`, `drop`, `slice`, `remove`, `rename` and `assign` accept a block.

This is an exaple to eliminate observations (row in table) containing nil.

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

See [DataFrame.md](doc/DataFrame.md) for details.


## `RedAmber::Vector`

Class `RedAmber::Vector` represents a series of data in the DataFrame.

```ruby
penguins[:species]
# =>
#<RedAmber::Vector(:string, size=344):0x000000000000f8e8>
["Adelie", "Adelie", "Adelie", "Adelie", "Adelie", "Adelie", "Adelie", "Adelie", ... ]
```

Vectors accepts some [functional methods from Arrow](https://arrow.apache.org/docs/cpp/compute.html).

See [Vector.md](doc/Vector.md) for details.

## TDR concept

I named the data frame representation style in the model above as TDR (Transposed DataFrame Representation). See [TDR.md](doc/tdr.md) for details.

## Development

```shell
git clone https://github.com/heronshoes/red_amber.git
cd red_amber
bundle install
bundle exec rake test
```

## License

The gem is available as open source under the terms of the [MIT License](https://opensource.org/licenses/MIT).
