# RedAmber Minimal Notebook

This is a docker image containing RedAmber created from 
[jupyter/minimal-notebook](https://jupyter-docker-stacks.readthedocs.io/en/latest/using/selecting.html#jupyter-minimal-notebook)

## Contents

- From jupyter/minimal-notebook:
  - Based on 2023-03-13 (295612d3ade4)
  - x86-64
  - Ubuntu-22.04
  - python-3.10.9
  - lab-3.6.1
  - notebook-6.5.3
- System ruby-dev:
  - Ruby 3.0.2
- Arrow 11.0.0 for Ubuntu:
  - libarrow-dev
  - libarrow-glib-dev
  - libparquet-dev
  - libparquet-glib-dev
- Locally installed iruby:
  - Using Ruby 3.0.2
- Locally installed bundler and Gemfile:
  - RedAmber 0.4.1
  - Others (see Gemfile)

## Install

```
git clone https://github.com/heronshoes/red_amber.git
cd  docker
```

Edit ENV variable in `.env` as you like.

[note:] NB_USER is fixed for `jovyan`, the common user name in Jupyter.
It can not change in this version.

If TZ is not used in your system, define it here.
Otherwise UTC is used in the container.

TOKEN will be used for token-based authentication.

```
# Example
TZ=Asia/Tokyo
TOKEN='something'
```

Then build `red_amber-minimal-notebook` container. It will take a while.

```
docker-compose build
```

## Start Jupyter Lab

After build, start the container. Adding `-d` option will detach it in background.

```
docker-compose up
```

You can access Jupyter Lab from `http://localhost:8888/` in your browser.

- `red-amber.ipynb`:
  - Walks through the [README of RedAmber](https://github.com/heronshoes/red_amber#readme).
- `examples_of_red_amber.ipynb`:
  - Examples of RedAmber in Notebook style.

## Example in irb

You can try RedAmber in irb with pre-loaded datasets in Jupyter.

Start `terminal`.

For the first time,
```
source ~/.bashrc
../example
```

It will take a while for the first run to fetch and prepare red-datasets cache.

If irb starts you can see:

```ruby

    70: # Welcome to RedAmber example!
    71: # This environment will offer these pre-loaded datasets:
    72: #   penguins, diamonds, starwars, simpsons_paradox_covid
    73: #   (nycflights13) flights, airlines, airports, planes, weather
    74: #   (original) import_cars, comecome, dataframe, subframes
 => 75: binding.irb

irb(main):001:0> 
```

RedAmber is already loaded in this environment with some datasets shown above.

```ruby
irb(main):002:0> dataframe
=> 
#<RedAmber::DataFrame : 6 x 3 Vectors, 0x0000000000003818>
        x y        z
  <uint8> <string> <boolean>
0       1 A        false
1       2 A        true
2       3 B        false
3       4 B        (nil)
4       5 B        true
5       6 C        false
```

Next time you start this environment, you can simply invoke as `../example`.
