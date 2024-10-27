# RedAmber

[![Gem Version](https://img.shields.io/gem/v/red_amber?color=brightgreen)](https://rubygems.org/gems/red_amber)
[![CI](https://github.com/heronshoes/red_amber/actions/workflows/ci.yml/badge.svg)](https://github.com/red-data-tools/red_amber/actions/workflows/ci.yml)
[![Maintainability](https://api.codeclimate.com/v1/badges/b8a745047045d2f49daa/maintainability)](https://codeclimate.com/github/heronshoes/red_amber/maintainability)
[![Test coverage](https://api.codeclimate.com/v1/badges/b8a745047045d2f49daa/test_coverage)](https://codeclimate.com/github/heronshoes/red_amber/test_coverage)
[![Doc](https://img.shields.io/badge/docs-latest-blue)](https://red-data-tools.github.io/red_amber/)
[![Discussions](https://img.shields.io/github/discussions/heronshoes/red_amber)](https://github.com/red-data-tools/red_amber/discussions)

A dataframe library for Rubyists.

- Powered by [Red Arrow](https://github.com/apache/arrow/tree/master/ruby/red-arrow)
[![Red Data Tools Chat (en)](https://badges.gitter.im/red-data-tools/en.svg)](https://app.element.io/#/room/#red-data-tools_en:gitter.im) [![Gem Version](https://img.shields.io/gem/v/red-arrow?color=brightgreen)](https://rubygems.org/gems/red-arrow)
- Inspired by the dataframe library [Rover-df](https://github.com/ankane/rover)

[日本語のREADME](README.ja.md)

![screenshot from jupyterlab](https://raw.githubusercontent.com/red-data-tools/red_amber/main/doc/image/screenshot.png)

## Overview
* RedAmber is a dataframe library written in ruby. It uses columnar memory format based on [Apache Arrow](https://arrow.apache.org/).
* Our goal is to manipulate data frames in a Ruby-like writing style using blocks and collections.
* You can easily try RedAmber with [Dev Container](https://containers.dev/). See [RedAmber Dev Container](doc/Dev_Containers.md).
* We have [rich document with many examples](https://red-data-tools.github.io/red_amber/) and Jupyter Notebook with 127 operation examples. See [RedAmber Dev Container](doc/Dev_Containers.md).

## Requirements
### Ruby
Supported Ruby version is >= 3.0.

### Required libraries
```ruby
gem 'red-arrow',   '>= 12.0.0' # Requires Apache Arrow (see installation below).
gem 'red-arrow-numo-narray'    # Optional, recommended if you use inputs from Numo::NArray,
                               # or use random sampling feature.
gem 'red-parquet', '>= 12.0.0' # Optional, if you use IO from/to parquet.
gem 'red-datasets-arrow'       # Optional, if you use Red Datasets.
gem 'red-arrow-activerecord'   # Optional, if you use Active Record.
gem 'rover-df'                 # Optional, if you use IO from/to Rover::DataFrame.
```

## Installation

Install requirements before you install RedAmber.

- Apache Arrow (>= 12.0.0)
- Apache Arrow GLib (>= 12.0.0)
- Apache Parquet GLib (>= 12.0.0)  # If you use IO from/to parquet

See [Apache Arrow install document](https://arrow.apache.org/install/).

  - Minimum installation example for the latest Ubuntu:

      ```
      sudo apt update
      sudo apt install -y -V ca-certificates lsb-release wget
      wget https://apache.jfrog.io/artifactory/arrow/$(lsb_release --id --short | tr 'A-Z' 'a-z')/apache-arrow-apt-source-latest-$(lsb_release --codename --short).deb
      sudo apt install -y -V ./apache-arrow-apt-source-latest-$(lsb_release --codename --short).deb
      sudo apt update
      sudo apt install -y -V libarrow-dev libarrow-glib-dev
      ```

  - On Fedora 39 (Rawhide):

      ```
      sudo dnf update
      sudo dnf -y install gcc-c++ libarrow-devel libarrow-glib-devel ruby-devel libyaml-devel
      ```

  - On macOS, using Homebrew:

      ```
      brew install apache-arrow apache-arrow-glib
      ```

If you prepared Apache Arrow, add these lines to your Gemfile:

```ruby
gem 'red-arrow',   '>= 12.0.0'
gem 'red_amber'
gem 'red-arrow-numo-narray'    # Optional, recommended if you use inputs from Numo::NArray
                               # or use random sampling feature.
gem 'red-parquet', '>= 12.0.0' # Optional, if you use IO from/to parquet
gem 'red-datasets-arrow'       # Optional, recommended if you use Red Datasets
gem 'red-arrow-activerecord'   # Optional, if you use Active Record
gem 'rover-df',                # Optional, if you use IO from/to Rover::DataFrame.
```

And then execute `bundle install` or install them yourself such as `gem install red_amber`.

## Development Containers

This repository supports [Dev Containers](https://containers.dev/). You can create a container as a full-featured development environment for RedAmber. The environment includes Ruby, Apache Arrow, RedAmber with source tree, GitHub CLI, sample datasets and Jupyter Lab with IRuby kernel. And you don't need to worry about the change of your local environment.

`.devcontainer` directory in this repository includes settings of Dev Container for RedAmber.
Please refer [How to use Dev Containers in RedAmber](doc/Dev_Containers.md) to use it.

## Docker image and Jupyter Notebook

(Notice: This feature may be removed in the future. Try Dev Container above.)

Docker image is available from `docker` folder. See [readme](docker/readme.md) for instruction. Integrated Jypyter notebook is in docker/notebook folder.

You can try the contents of this README interactively by [Binder](https://mybinder.org/v2/gh/heronshoes/docker-stacks/RedAmber-binder?filepath=red-amber.ipynb).
[![Binder](https://mybinder.org/badge_logo.svg)](https://mybinder.org/v2/gh/heronshoes/docker-stacks/RedAmber-binder?filepath=red-amber.ipynb)

[RubyData Docker Stacks](https://github.com/RubyData/docker-stacks) is available as a ready-to-run Docker image containing Jupyter and useful data tools as well as RedAmber (Thanks to Kenta Murata).

## Comparison of DataFrames

Comparison of  basic features of RedAmber with Python
[pandas](https://pandas.pydata.org/),
R [Tidyverse](https://www.tidyverse.org/) and
Julia [Dataframes](https://dataframes.juliadata.org/stable/) is in [DataFrame_Comparison.md](doc/DataFrame_Comparison.md) (Thanks to Benson Muite).

## Data frame in `RedAmber`

Class `RedAmber::DataFrame` represents a set of data in 2D-shape.
Its entity is a Red Arrow's Table object.

![dataframe model of RedAmber](https://raw.githubusercontent.com/red-data-tools/red_amber/main/doc/image/dataframe_model.png)

Let's load the library and try some examples.

```ruby
require 'red_amber' # require 'red-amber' is also OK.
include RedAmber
```

### Example: diamonds dataset

First do (if you do not installed) `
gem install red-datasets-arrow
`
then

```ruby
require 'datasets-arrow' # to load sample data

dataset = Datasets::Diamonds.new
diamonds = DataFrame.new(dataset) # before v0.2.3, should be `dataset.to_arrow`

# =>
#<RedAmber::DataFrame : 53940 x 10 Vectors, 0x000000000000f668>
         carat cut       color    clarity     depth    table    price        x ...        z
      <double> <string>  <string> <string> <double> <double> <uint16> <double> ... <double>
    0     0.23 Ideal     E        SI2          61.5     55.0      326     3.95 ...     2.43
    1     0.21 Premium   E        SI1          59.8     61.0      326     3.89 ...     2.31
    2     0.23 Good      E        VS1          56.9     65.0      327     4.05 ...     2.31
    3     0.29 Premium   I        VS2          62.4     58.0      334      4.2 ...     2.63
    4     0.31 Good      J        SI2          63.3     58.0      335     4.34 ...     2.75
    :        : :         :        :               :        :        :        : ...        :
53937      0.7 Very Good D        SI1          62.8     60.0     2757     5.66 ...     3.56
53938     0.86 Premium   H        SI2          61.0     58.0     2757     6.15 ...     3.74
53939     0.75 Ideal     D        SI2          62.2     55.0     2757     5.83 ...     3.64
```

For example, we can compute mean prices per cut for the data larger than 1 carat.

```ruby
df = diamonds
  .slice { carat > 1 } # or use #filter instead of #slice
  .group(:cut)
  .mean(:price) # `pick` prior to `group` is not required if `:price` is specified here.
  .sort('-mean(price)')

# =>
#<RedAmber::DataFrame : 5 x 2 Vectors, 0x000000000000f67c>
  cut       mean(price)
  <string>     <double>
0 Ideal         8674.23
1 Premium       8487.25
2 Very Good     8340.55
3 Good           7753.6
4 Fair          7177.86
```

Arrow data is immutable, so these methods always return new objects.
Next example will rename a column and create a new column by simple calcuration.

```ruby
usdjpy = 110.0 # when the yen was stronger

df.rename('mean(price)': :mean_price_USD)
  .assign(:mean_price_JPY) { mean_price_USD * usdjpy }

# =>
#<RedAmber::DataFrame : 5 x 3 Vectors, 0x000000000000f71c>
  cut       mean_price_USD mean_price_JPY
  <string>        <double>       <double>
0 Ideal            8674.23      954164.93
1 Premium          8487.25      933597.34
2 Very Good        8340.55      917460.37
3 Good              7753.6      852896.11
4 Fair             7177.86      789564.12
```

### Example: starwars dataset

Next example is `starwars` dataset reading from the downloaded CSV file. Followed by minimum data cleaning.

```ruby
uri = URI('https://vincentarelbundock.github.io/Rdatasets/csv/dplyr/starwars.csv')

starwars = DataFrame.load(uri)

starwars
  .drop(0) # delete unnecessary index column
  .remove { species == "NA" } # delete unnecessary rows
  .group(:species) { [count(:species), mean(:height, :mass)] }
  .slice { count > 1 } # or use #filter instead of slice

# =>
#<RedAmber::DataFrame : 8 x 4 Vectors, 0x000000000000f848>
  species    count mean(height) mean(mass)
  <string> <int64>     <double>   <double>
0 Human         35       176.65      82.78
1 Droid          6        131.2      69.75
2 Wookiee        2        231.0      124.0
3 Gungan         3       208.67       74.0
4 Zabrak         2        173.0       80.0
5 Twi'lek        2        179.0       55.0
6 Mirialan       2        168.0       53.1
7 Kaminoan       2        221.0       88.0
```

See [DataFrame.md](doc/DataFrame.md) for other examples and details.


### `Vector` for 1D data object in column

Class `RedAmber::Vector` represents a series of data in the DataFrame.

See [Vector.md](doc/Vector.md) for details.

## Jupyter notebook

We are managing the source of Jupyter Notebook in qmd format by Quarto. You can easily create Notebooks and try it with Jupyter Lab in [Dev Container](doc/Dev_Containers.md).

## Development

The recommended way to develop RedAmber is to use Dev Container. Please refer [How to use Dev Containers in RedAmber](doc/Dev_Containers.md) to use it.

Otherwise run below commands after install required libraries in your local system.

```shell
git clone https://github.com/red-data-tools/red_amber.git
cd red_amber
bundle install
bundle exec rake test
```

We need to pass `rake test` in development of RedAmber, but not require to pass `rake rubocop` when you make a contribution. In this project we respect your preferences in code style. However, we may unify the style during merging.

## Community

I will appreciate if you could help to improve this project. Here are a few ways you can help:

- Let's talk in the [discussions](https://github.com/heronshoes/red_amber/discussions). [![Discussions](https://img.shields.io/github/discussions/heronshoes/red_amber)](https://github.com/red-data-tools/red_amber/discussions)
  - Browse Q and A, how to use, tips, etc.
  - Ask questions you’re wondering about.
  - Share ideas. The idea may be promoted to issues or pull requests.
- [Report bugs or suggest new features](https://github.com/red-data-tools/red_amber/issues)
- Fix bugs and [submit pull requests](https://github.com/red-data-tools/red_amber/pulls)
- Write, clarify, or fix documentation

## License

The gem is available as open source under the terms of the [MIT License](https://opensource.org/licenses/MIT).
