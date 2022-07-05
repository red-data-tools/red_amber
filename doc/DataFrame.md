# DataFrame

Class `RedAmber::DataFrame` represents 2D-data. A `DataFrame` consists with:
- A collection of data which have same data type within. We call it `Vector`.
- A label is attached to `Vector`. We call it `key`.
- A `Vector` and associated `key` is grouped as a `variable`.
- `variable`s with same vector length are aligned and arranged to be a `DataFrame`.
- Each `Vector` in a `DataFrame` contains a set of relating data at same position. We call it `observation`.

![dataframe model image](doc/../image/dataframe_model.png)

## Constructors and saving

### `new` from a Hash

  ```ruby
  RedAmber::DataFrame.new(x: [1, 2, 3])
  ```

### `new` from a schema (by Hash) and data (by Array)

  ```ruby
  RedAmber::DataFrame.new({:x=>:uint8}, [[1], [2], [3]])
  ```

### `new` from an Arrow::Table


  ```ruby
  table = Arrow::Table.new(x: [1, 2, 3])
  RedAmber::DataFrame.new(table)
  ```

### `new` from a Rover::DataFrame


  ```ruby
  rover = Rover::DataFrame.new(x: [1, 2, 3])
  RedAmber::DataFrame.new(rover)
  ```

### `load` (class method)

- from a `.arrow`, `.arrows`, `.csv`, `.csv.gz` or `.tsv` file
       
  ```ruby
  RedAmber::DataFrame.load("test/entity/with_header.csv")
  ```

- from a string buffer

- from a URI

  ```ruby
  uri = URI("https://raw.githubusercontent.com/mwaskom/seaborn-data/master/penguins.csv")
  RedAmber::DataFrame.load(uri)
  ```

- from a Parquet file

  ```ruby
  dataframe = RedAmber::DataFrame.load("file.parquet")
  ```

### `save` (instance method)

- to a `.arrow`, `.arrows`, `.csv`, `.csv.gz` or `.tsv` file

- to a string buffer

- to a URI

- to a Parquet file

  ```ruby
  dataframe.save("file.parquet")
  ```

## Properties

### `table`, `to_arrow`

- Reader of Arrow::Table object inside.

### `size`, `n_obs`, `n_rows`
  
- Returns size of Vector (num of observations).
 
### `n_keys`, `n_vars`, `n_cols`,
  
- Returns num of keys (num of variables).
 
### `shape`
 
- Returns shape in an Array[n_rows, n_cols].

### `variables`

- Returns key names and Vectors pair in a Hash.

  It is convenient to use in a block when both key and vector required. We will write:

  ```ruby
    # update numeric variables
    df.assign do
      variables.select.with_object({}) do |(key, vector), assigner|
        assigner[key] = vector * -1 if vector.numeric?
      end
    end
  ```

  Instead of:
  ```ruby
    df.assign do
      assigner = {}
      vectors.each_with_index do |vector, i|
        assigner[keys[i]] = vector * -1 if vector.numeric?
      end
      assigner
    end
  ```

### `keys`, `var_names`, `column_names`
  
- Returns key names in an Array.

  When we use it with vectors, Vector#key is useful to get the key inside of DataFrame.

  ```ruby
    # update numeric variables, another solution
    df.assign do
      vectors.each_with_object({}) do |vector, assigner|
        assigner[vector.key] = vector * -1 if vector.numeric?
      end
    end
  ```

### `types`
  
- Returns types of vectors in an Array of Symbols.

### `type_classes`

- Returns types of vector in an Array of `Arrow::DataType`.

### `vectors`

- Returns an Array of Vectors.

### `indices`, `indexes`

- Returns all indexes in an Array.

### `to_h`

- Returns column-oriented data in a Hash.

### `to_a`, `raw_records`

- Returns an array of row-oriented data without header.
  
  If you need a column-oriented full array, use `.to_h.to_a`

### `schema`

- Returns column name and data type in a Hash.

### `==`
 
### `empty?`

## Output

### `to_s`

### `summary`, `describe` (not implemented)

### `to_rover`

- Returns a `Rover::DataFrame`.

### `to_iruby`

- Show the DataFrame as a Table in Jupyter Notebook or Jupyter Lab with IRuby.

### `tdr(limit = 10, tally: 5, elements: 5)`

  - Shows some information about self in a transposed style.
  - `tdr_str` returns same info as a String.

  ```ruby
  require 'red_amber'
  require 'datasets-arrow'

  penguins = Datasets::Penguins.new.to_arrow
  RedAmber::DataFrame.new(penguins).tdr
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

  - limit: limit of variables to show. Default value is 10.
  - tally: max level to use tally mode.
  - elements: max num of element to show values in each observations.

### `inspect`

## Selecting

### Select variables (columns in a table) by `[]` as `[key]`, `[keys]`, `[keys[index]]`
- Key in a Symbol: `df[:symbol]`
- Key in a String: `df["string"]`
- Keys in an Array: `df[:symbol1, "string", :symbol2]`
- Keys by indeces: `df[df.keys[0]`, `df[df.keys[1,2]]`, `df[df.keys[1..]]`

  Key indeces can be used via `keys[i]` because numbers are used to select observations (rows).

- Keys by a Range:

  If keys are able to represent by Range, it can be included in the arguments. See a example below.

- You can exchange the order of variables (columns).
 
  ```ruby
  hash = {a: [1, 2, 3], b: %w[A B C], c: [1.0, 2, 3]}
  df = RedAmber::DataFrame.new(hash)
  df[:b..:c, "a"]
  # =>
  #<RedAmber::DataFrame : 3 x 3 Vectors, 0x00000000000081b0>
          b                c      a
  0       A         1.000000      1
  1       B         2.000000      2
  2       C         3.000000      3
  ```

  If `#[]` represents single variable (column), it returns a Vector object.

  ```ruby
  df[:a]
  # =>
  #<RedAmber::Vector(:uint8, size=3):0x000000000000f140>
  [1, 2, 3]
  ```
  Or `#v` method also returns a Vector for a key.

  ```ruby
  df.v(:a)
  # =>
  #<RedAmber::Vector(:uint8, size=3):0x000000000000f140>
  [1, 2, 3]
  ```

  This may be useful to use in a block of DataFrame manipulation verbs. We can write `v(:a)` rather than `self[:a]` or `df[:a]`

### Select observations (rows in a table) by `[]` as `[index]`, `[range]`, `[array]`

- Select a obs. by index: `df[0]`
- Select obs. by indeces in a Range: `df[1..2]`

  An end-less or a begin-less Range can be used to represent indeces.

- Select obs. by indeces in an Array: `df[1, 2]`

- You can use float indices.

- Mixed case: `df[2, 0..]`

  ```ruby
  hash = {a: [1, 2, 3], b: %w[A B C], c: [1.0, 2, 3]}
  df = RedAmber::DataFrame.new(hash)
  df[2, 0..]
  # =>
  #<RedAmber::DataFrame : 4 x 3 Vectors, 0x0000000000020cb0>
          a       b                c
  0       3       C         3.000000
  1       1       A         1.000000
  2       2       B         2.000000
  3       3       C         3.000000
  ```

- Select obs. by a boolean Array or a boolean RedAmber::Vector at same size as self.

  It returns a sub dataframe with observations at boolean is true.

    ```ruby
    # with the same dataframe `df` above
    df[true, false, nil] # or
    df[[true, false, nil]] # or
    df[RedAmber::Vector.new([true, false, nil])]
    # =>
    #<RedAmber::DataFrame : 1 x 3 Vectors, 0x0000000000022010>
            a       b                c
    0       1       A         1.000000
    ```

### Select rows from top or from bottom

  `head(n=5)`, `tail(n=5)`, `first(n=1)`, `last(n=1)`

## Sub DataFrame manipulations

### `pick  ` - pick up variables by key label -

  Pick up some variables (columns) to create a sub DataFrame.

  ![pick method image](doc/../image/dataframe/pick.png)

- Keys as arguments

  `pick(keys)` accepts keys as arguments in an Array.

    ```ruby
    penguins.pick(:species, :bill_length_mm)
    # =>
    #<RedAmber::DataFrame : 344 x 2 Vectors, 0x0000000000046eb0>    
           species  bill_length_mm                                  
      0     Adelie       39.100000                                  
      1     Adelie       39.500000                                  
      2     Adelie       40.300000                                  
      3     Adelie          (null)                                  
      4     Adelie       36.700000                                  
      5     Adelie       39.300000                                  
      6     Adelie       38.900000                                  
      7     Adelie       39.200000                                  
      8     Adelie       34.100000                                  
      9     Adelie       42.000000                                  
    ...
    334     Gentoo       46.200000
    335     Gentoo       55.100000
    336     Gentoo       44.500000
    337     Gentoo       48.800000
    338     Gentoo       47.200000
    339     Gentoo          (null)
    340     Gentoo       46.800000
    341     Gentoo       50.400000
    342     Gentoo       45.200000
    343     Gentoo       49.900000
    ```

- Booleans as a argument

  `pick(booleans)` accepts booleans as a argument in an Array. Booleans must be same length as `n_keys`.

    ```ruby
    penguins.pick(penguins.types.map { |type| type == :string })
    # =>
    #<RedAmber::DataFrame : 344 x 3 Vectors, 0x0000000000049638>
           species     island       sex
      0     Adelie  Torgersen       male
      1     Adelie  Torgersen       female
      2     Adelie  Torgersen       female
      3     Adelie  Torgersen       (null)
      4     Adelie  Torgersen       female
      5     Adelie  Torgersen       male
      6     Adelie  Torgersen       female
      7     Adelie  Torgersen       male
      8     Adelie  Torgersen       (null)
      9     Adelie  Torgersen       (null)
    ...
    334     Gentoo  Biscoe          female
    335     Gentoo  Biscoe          male
    336     Gentoo  Biscoe          (null)
    337     Gentoo  Biscoe          male
    338     Gentoo  Biscoe          female
    339     Gentoo  Biscoe          (null)
    340     Gentoo  Biscoe          female
    341     Gentoo  Biscoe          male
    342     Gentoo  Biscoe          female
    343     Gentoo  Biscoe          male
    ```

 - Keys or booleans by a block

    `pick {block}` is also acceptable. We can't use both arguments and a block at a same time. The block should return keys, or a boolean Array with a same length as `n_keys`. Block is called in the context of self.

    ```ruby
    #<RedAmber::DataFrame : 344 x 3 Vectors, 0x000000000004c180>
            bill_length_mm  bill_depth_mm   flipper_length_mm
      0          39.100000      18.700000                 181
      1          39.500000      17.400000                 186
      2          40.300000      18.000000                 195
      3             (null)         (null)              (null)
      4          36.700000      19.300000                 193
      5          39.300000      20.600000                 190
      6          38.900000      17.800000                 181
      7          39.200000      19.600000                 195
      8          34.100000      18.100000                 193
      9          42.000000      20.200000                 190
    ...
    334          46.200000      14.100000                 217
    335          55.100000      16.000000                 230
    336          44.500000      15.700000                 217
    337          48.800000      16.200000                 222
    338          47.200000      13.700000                 214
    339             (null)         (null)              (null)
    340          46.800000      14.300000                 215
    341          50.400000      15.700000                 222
    342          45.200000      14.800000                 212
    343          49.900000      16.100000                 213
    ```

### `drop  ` - pick and drop -

  Drop some variables (columns) to create a remainer DataFrame.

  ![drop method image](doc/../image/dataframe/drop.png)

- Keys as arguments

  `drop(keys)` accepts keys as arguments in an Array.

- Booleans as a argument

  `drop(booleans)` accepts booleans as a argument in an Array. Booleans must be same length as `n_keys`.

- Keys or booleans by a block

  `drop {block}` is also acceptable. We can't use both arguments and a block at a same time. The block should return keys, or a boolean Array with a same length as `n_keys`. Block is called in the context of self.
  
- Notice for nil

  When used with booleans, nil in booleans is treated as a false. This behavior is aligned with Ruby's `nil#!`.

  ```ruby
  booleans = [true, false, nil]
  booleans_invert = booleans.map(&:!) # => [false, true, true]
  df.pick(booleans) == df.drop(booleans_invert) # => true
  ```
- Difference between `pick`/`drop` and `[]`

  If `pick` or `drop` will select a single variable (column), it returns a `DataFrame` with one variable. In contrast, `[]` returns a `Vector`. This behavior may be useful to use in a block of DataFrame manipulations.

  ```ruby
  df = RedAmber::DataFrame.new(a: [1, 2, 3], b: %w[A B C], c: [1.0, 2, 3])
  df.pick(:a) # or
  df.drop(:b, :c)
  # =>
  #<RedAmber::DataFrame : 3 x 1 Vectors, 0x000000000005094c>
          a      
  0       1      
  1       2      
  2       3

  df[:a]
  # =>
  #<RedAmber::Vector(:uint8, size=3):0x000000000000f258>
  [1, 2, 3]
  ```

### `slice  `  - to cut vertically is slice -

  Slice and select observations (rows) to create a sub DataFrame.

  ![slice method image](doc/../image/dataframe/slice.png)

- Indices as arguments

    `slice(indeces)` accepts indices as arguments. Indices should be Integers, Floats or Ranges of Integers.

    Negative index from the tail like Ruby's Array is also acceptable.

    ```ruby
    # returns 5 obs. at start and 5 obs. from end
    penguins.slice(0...5, -5..-1)
    # =>
    #<RedAmber::DataFrame : 10 x 8 Vectors, 0x0000000000055fdc>           
            species island  bill_length_mm  bill_depth_mm   flipper_length_mm     body_mass_g     sex     year                                  
     0      Adelie  Torgersen    39.100000      18.700000                 181            3750     male    2007                          
     1      Adelie  Torgersen    39.500000      17.400000                 186            3800     female  2007
     2      Adelie  Torgersen    40.300000      18.000000                 195            3250     female  2007
     3      Adelie  Torgersen       (null)         (null)              (null)          (null)     (null)  2007
     4      Adelie  Torgersen    36.700000      19.300000                 193            3450     female  2007
     5      Gentoo  Biscoe          (null)         (null)              (null)          (null)     (null)  2009
     6      Gentoo  Biscoe       46.800000      14.300000                 215            4850     female  2009
     7      Gentoo  Biscoe       50.400000      15.700000                 222            5750     male    2009
     8      Gentoo  Biscoe       45.200000      14.800000                 212            5200     female  2009
     9      Gentoo  Biscoe       49.900000      16.100000                 213            5400     male    2009
    ```

- Booleans as an argument

  `slice(booleans)` accepts booleans as a argument in an Array, a Vector or an Arrow::BooleanArray . Booleans must be same length as `size`.

    ```ruby
    vector = penguins[:bill_length_mm]
    penguins.slice(vector >= 40)
    # =>
    #<RedAmber::DataFrame : 242 x 8 Vectors, 0x00000000000584f8>
            species island  bill_length_mm  bill_depth_mm   flipper_length_mm     body_mass_g     sex     year
      0     Adelie  Torgersen    40.300000      18.000000                 195            3250     female  2007
      1     Adelie  Torgersen    42.000000      20.200000                 190            4250     (null)  2007
      2     Adelie  Torgersen    41.100000      17.600000                 182            3200     female  2007
      3     Adelie  Torgersen    42.500000      20.700000                 197            4500     male    2007
      4     Adelie  Torgersen    46.000000      21.500000                 194            4200     male    2007
      5     Adelie  Biscoe       40.600000      18.600000                 183            3550     male    2007
      6     Adelie  Biscoe       40.500000      17.900000                 187            3200     female  2007
      7     Adelie  Biscoe       40.500000      18.900000                 180            3950     male    2007
      8     Adelie  Dream        40.900000      18.900000                 184            3900     male    2007
      9     Adelie  Dream        42.200000      18.500000                 180            3550     female  2007
    ...
    232     Gentoo  Biscoe       51.500000      16.300000                 230            5500     male    2009
    233     Gentoo  Biscoe       46.200000      14.100000                 217            4375     female  2009
    234     Gentoo  Biscoe       55.100000      16.000000                 230            5850     male    2009
    235     Gentoo  Biscoe       44.500000      15.700000                 217            4875     (null)  2009
    236     Gentoo  Biscoe       48.800000      16.200000                 222            6000     male    2009
    237     Gentoo  Biscoe       47.200000      13.700000                 214            4925     female  2009
    238     Gentoo  Biscoe       46.800000      14.300000                 215            4850     female  2009
    239     Gentoo  Biscoe       50.400000      15.700000                 222            5750     male    2009
    240     Gentoo  Biscoe       45.200000      14.800000                 212            5200     female  2009
    241     Gentoo  Biscoe       49.900000      16.100000                 213            5400     male    2009
    ```

- Indices or booleans by a block

    `slice {block}` is also acceptable. We can't use both arguments and a block at a same time. The block should return indeces or a boolean Array with a same length as `size`. Block is called in the context of self.

    ```ruby
    # return a DataFrame with bill_length_mm is in 2*std range around mean
    penguins.slice do
      vector = self[:bill_length_mm]
      min = vector.mean - vector.std
      max = vector.mean + vector.std
      vector.to_a.map { |e| (min..max).include? e }
    end

    # =>
    #<RedAmber::DataFrame : 204 x 8 Vectors, 0x000000000005fca8>
            species island  bill_length_mm  bill_depth_mm   flipper_length_mm     body_mass_g     sex     year
      0     Adelie  Torgersen    39.100000      18.700000                 181            3750     male    2007
      1     Adelie  Torgersen    39.500000      17.400000                 186            3800     female  2007
      2     Adelie  Torgersen    40.300000      18.000000                 195            3250     female  2007
      3     Adelie  Torgersen    39.300000      20.600000                 190            3650     male    2007
      4     Adelie  Torgersen    38.900000      17.800000                 181            3625     female  2007
      5     Adelie  Torgersen    39.200000      19.600000                 195            4675     male    2007
      6     Adelie  Torgersen    42.000000      20.200000                 190            4250     (null)  2007
      7     Adelie  Torgersen    41.100000      17.600000                 182            3200     female  2007
      8     Adelie  Torgersen    38.600000      21.200000                 191            3800     male    2007
      9     Adelie  Torgersen    38.700000      19.000000                 195            3450     female  2007
    ...
    194     Gentoo  Biscoe       41.700000      14.700000                 210            4700     female  2009
    195     Gentoo  Biscoe       43.300000      14.000000                 208            4575     female  2009
    196     Gentoo  Biscoe       48.100000      15.100000                 209            5500     male    2009
    197     Gentoo  Biscoe       43.500000      15.200000                 213            4650     female  2009
    198     Gentoo  Biscoe       46.200000      14.100000                 217            4375     female  2009
    199     Gentoo  Biscoe       44.500000      15.700000                 217            4875     (null)  2009
    200     Gentoo  Biscoe       48.800000      16.200000                 222            6000     male    2009
    201     Gentoo  Biscoe       47.200000      13.700000                 214            4925     female  2009
    202     Gentoo  Biscoe       46.800000      14.300000                 215            4850     female  2009
    203     Gentoo  Biscoe       45.200000      14.800000                 212            5200     female  2009
    ```

- Notice: nil option
  - `Arrow::Table#slice` uses `filter` method with a option `Arrow::FilterOptions.null_selection_behavior = :emit_null`. This will propagate nil at the same row.
    
    ```ruby
    hash = { a: [1, 2, 3], b: %w[A B C], c: [1.0, 2, 3] }
    table = Arrow::Table.new(hash)
    table.slice([true, false, nil])
    # =>
    #<Arrow::Table:0x7fdfe44b9e18 ptr=0x555e9fe744d0>
	         a	b	            c
    0	     1  A      1.000000
    1	(null)	(null)   (null)
    ```

  - Whereas in RedAmber, `DataFrame#slice` with booleans containing nil is treated as false. This behavior comes from `Allow::FilterOptions.null_selection_behavior = :drop`. This is  a default value for `Arrow::Table.filter` method.

    ```ruby
    RedAmber::DataFrame.new(table).slice([true, false, nil]).table
    # =>
    #<Arrow::Table:0x7fdfe44981c8 ptr=0x555e9febc330>
	    a	b	         c
    0	1	A	  1.000000
    ``` 

### `remove`

  Slice and reject observations (rows) to create a remainer DataFrame.

  ![remove method image](doc/../image/dataframe/remove.png)

- Indices as arguments

    `remove(indeces)` accepts indeces as arguments. Indeces should be an Integer or a Range of Integer.

    ```ruby
    # returns 6th to 339th obs.
    penguins.remove(0...5, -5..-1)
    # =>
    #<RedAmber::DataFrame : 334 x 8 Vectors, 0x0000000000060964>
            species island  bill_length_mm  bill_depth_mm   flipper_length_mm     body_mass_g     sex     year
      0     Adelie  Torgersen    39.300000      20.600000                 190            3650     male    2007
      1     Adelie  Torgersen    38.900000      17.800000                 181            3625     female  2007
      2     Adelie  Torgersen    39.200000      19.600000                 195            4675     male    2007
      3     Adelie  Torgersen    34.100000      18.100000                 193            3475     (null)  2007
      4     Adelie  Torgersen    42.000000      20.200000                 190            4250     (null)  2007
      5     Adelie  Torgersen    37.800000      17.100000                 186            3300     (null)  2007
      6     Adelie  Torgersen    37.800000      17.300000                 180            3700     (null)  2007
      7     Adelie  Torgersen    41.100000      17.600000                 182            3200     female  2007
      8     Adelie  Torgersen    38.600000      21.200000                 191            3800     male    2007
      9     Adelie  Torgersen    34.600000      21.100000                 198            4400     male    2007
    ...
    324     Gentoo  Biscoe       48.100000      15.100000                 209            5500     male    2009
    325     Gentoo  Biscoe       50.500000      15.200000                 216            5000     female  2009
    326     Gentoo  Biscoe       49.800000      15.900000                 229            5950     male    2009
    327     Gentoo  Biscoe       43.500000      15.200000                 213            4650     female  2009
    328     Gentoo  Biscoe       51.500000      16.300000                 230            5500     male    2009
    329     Gentoo  Biscoe       46.200000      14.100000                 217            4375     female  2009
    330     Gentoo  Biscoe       55.100000      16.000000                 230            5850     male    2009
    331     Gentoo  Biscoe       44.500000      15.700000                 217            4875     (null)  2009
    332     Gentoo  Biscoe       48.800000      16.200000                 222            6000     male    2009
    333     Gentoo  Biscoe       47.200000      13.700000                 214            4925     female  2009
    ```

- Booleans as an argument

  `remove(booleans)` accepts booleans as a argument in an Array, a Vector or an Arrow::BooleanArray . Booleans must be same length as `size`.

    ```ruby
    # remove all observation contains nil
    removed = penguins.remove { vectors.map(&:is_nil).reduce(&:|) }
    removed
    # =>
    #<RedAmber::DataFrame : 333 x 8 Vectors, 0x0000000000064eb0>
            species island  bill_length_mm  bill_depth_mm   flipper_length_mm     body_mass_g     sex     year     
      0     Adelie  Torgersen    39.100000      18.700000                 181            3750     male    2007
      1     Adelie  Torgersen    39.500000      17.400000                 186            3800     female  2007
      2     Adelie  Torgersen    40.300000      18.000000                 195            3250     female  2007
      3     Adelie  Torgersen    36.700000      19.300000                 193            3450     female  2007
      4     Adelie  Torgersen    39.300000      20.600000                 190            3650     male    2007
      5     Adelie  Torgersen    38.900000      17.800000                 181            3625     female  2007
      6     Adelie  Torgersen    39.200000      19.600000                 195            4675     male    2007
      7     Adelie  Torgersen    41.100000      17.600000                 182            3200     female  2007
      8     Adelie  Torgersen    38.600000      21.200000                 191            3800     male    2007
      9     Adelie  Torgersen    34.600000      21.100000                 198            4400     male    2007
    ...
    323     Gentoo  Biscoe       43.500000      15.200000                 213            4650     female  2009
    324     Gentoo  Biscoe       51.500000      16.300000                 230            5500     male    2009
    325     Gentoo  Biscoe       46.200000      14.100000                 217            4375     female  2009
    326     Gentoo  Biscoe       55.100000      16.000000                 230            5850     male    2009
    327     Gentoo  Biscoe       48.800000      16.200000                 222            6000     male    2009
    328     Gentoo  Biscoe       47.200000      13.700000                 214            4925     female  2009
    329     Gentoo  Biscoe       46.800000      14.300000                 215            4850     female  2009
    330     Gentoo  Biscoe       50.400000      15.700000                 222            5750     male    2009
    331     Gentoo  Biscoe       45.200000      14.800000                 212            5200     female  2009
    332     Gentoo  Biscoe       49.900000      16.100000                 213            5400     male    2009
    ```

- Indices or booleans by a block

    `remove {block}` is also acceptable. We can't use both arguments and a block at a same time. The block should return indeces or a boolean Array with a same length as `size`. Block is called in the context of self.

    ```ruby
    penguins.remove do
      vector = self[:bill_length_mm]
      min = vector.mean - vector.std
      max = vector.mean + vector.std
      vector.to_a.map { |e| (min..max).include? e }
    end
    # =>
    #<RedAmber::DataFrame : 140 x 8 Vectors, 0x000000000006a158>
            species island  bill_length_mm  bill_depth_mm   flipper_length_mm     body_mass_g     sex     year
      0     Adelie  Torgersen       (null)         (null)              (null)          (null)     (null)  2007
      1     Adelie  Torgersen    36.700000      19.300000                 193            3450     female  2007
      2     Adelie  Torgersen    34.100000      18.100000                 193            3475     (null)  2007
      3     Adelie  Torgersen    37.800000      17.100000                 186            3300     (null)  2007
      4     Adelie  Torgersen    37.800000      17.300000                 180            3700     (null)  2007
      5     Adelie  Torgersen    34.600000      21.100000                 198            4400     male    2007
      6     Adelie  Torgersen    36.600000      17.800000                 185            3700     female  2007
      7     Adelie  Torgersen    34.400000      18.400000                 184            3325     female  2007
      8     Adelie  Biscoe       37.800000      18.300000                 174            3400     female  2007
      9     Adelie  Biscoe       37.700000      18.700000                 180            3600     male    2007    
    ...
    130     Gentoo  Biscoe       51.100000      16.500000                 225            5250     male    2009
    131     Gentoo  Biscoe       55.900000      17.000000                 228            5600     male    2009
    132     Gentoo  Biscoe       53.400000      15.800000                 219            5500     male    2009
    133     Gentoo  Biscoe       50.500000      15.200000                 216            5000     female  2009
    134     Gentoo  Biscoe       49.800000      15.900000                 229            5950     male    2009
    135     Gentoo  Biscoe       51.500000      16.300000                 230            5500     male    2009
    136     Gentoo  Biscoe       55.100000      16.000000                 230            5850     male    2009
    137     Gentoo  Biscoe          (null)         (null)              (null)          (null)     (null)  2009
    138     Gentoo  Biscoe       50.400000      15.700000                 222            5750     male    2009
    139     Gentoo  Biscoe       49.900000      16.100000                 213            5400     male    2009
    ```
- Notice for nil
  - When `remove` used with booleans, nil in booleans is treated as false. This behavior is aligned with Ruby's `nil#!`.

    ```ruby
    df = RedAmber::DataFrame.new(a: [1, 2, nil], b: %w[A B C], c: [1.0, 2, 3])
    booleans = df[:a] < 2
    # =>
    #<RedAmber::Vector(:boolean, size=3):0x000000000000f410>
    [true, false, nil]

    booleans_invert = booleans.to_a.map(&:!) # => [false, true, true]
    df.slice(booleans) == df.remove(booleans_invert) # => true
    ```
  - Whereas `Vector#invert` returns nil for elements nil. This will bring different result.

    ```ruby
    booleans.invert
    # =>
    #<RedAmber::Vector(:boolean, size=3):0x000000000000f488>
    [false, true, nil]

    df.remove(booleans.invert)
    #<RedAmber::DataFrame : 2 x 3 Vectors, 0x0000000000075d50>
                 a  b                c
    0            1  A         1.000000
    1       (null)  C         3.000000
    ```

### `rename`

  Rename keys (column names) to create a updated DataFrame.

  ![rename method image](doc/../image/dataframe/rename.png)

- Key pairs as arguments

    `rename(key_pairs)` accepts key_pairs as arguments. key_pairs should be a Hash of `{existing_key => new_key}`.

    ```ruby
    df = RedAmber::DataFrame.new( 'name' => %w[Yasuko Rui Hinata], 'age' => [68, 49, 28] )
    df.rename(:age => :age_in_1993)
    # =>
    #<RedAmber::DataFrame : 3 x 2 Vectors, 0x000000000007970c>
            name    age_in_1993
    0       Yasuko           68
    1       Rui              49
    2       Hinata           28
    ```

- Key pairs by a block

    `rename {block}` is also acceptable. We can't use both arguments and a block at a same time. The block should return key_pairs as a Hash of `{existing_key => new_key}`. Block is called in the context of self.

- Key type

  Symbol key and String key are distinguished.

### `assign`

  Assign new or updated variables (columns) and create a updated DataFrame.

  - Variables with new keys will append new variables at bottom (right in the table).
  - Variables with exisiting keys will update corresponding vectors.

    ![assign method image](doc/../image/dataframe/assign.png)

- Variables as arguments

    `assign(key_pairs)` accepts pairs of key and values as arguments. key_pairs should be a Hash of `{key => array}` or `{key => Vector}`.

    ```ruby
    df = RedAmber::DataFrame.new(
      name: %w[Yasuko Rui Hinata],
      age: [68, 49, 28])
    # =>
    #<RedAmber::DataFrame : 3 x 2 Vectors, 0x000000000007d794>
            name    age
    0       Yasuko   68
    1       Rui      49
    2       Hinata   28

    # update :age and add :brother
    assigner = { age: [97, 78, 57], brother: ['Santa', nil, 'Momotaro'] }
    df.assign(assigner)
    # =>
    #<RedAmber::DataFrame : 3 x 3 Vectors, 0x0000000000080610>
            name    age     brother
    0       Yasuko   97     Santa 
    1       Rui      78     (null)
    2       Hinata   57     Momotaro
    ```

- Key pairs by a block

    `assign {block}` is also acceptable. We can't use both arguments and a block at a same time. The block should return pairs of key and values as a Hash of `{key => array}` or `{key => Vector}`. Block is called in the context of self.

    ```ruby
    df = RedAmber::DataFrame.new(
      index: [0, 1, 2, 3, nil],
      float: [0.0, 1.1,  2.2, Float::NAN, nil],
      string: ['A', 'B', 'C', 'D', nil])
    # =>
    #<RedAmber::DataFrame : 5 x 3 Vectors, 0x00000000000885b8>
             index       float      string  
    0            0    0.000000      A       
    1            1    1.100000      B       
    2            2    2.200000      C       
    3            3         NaN      D       
    4       (null)      (null)      (null)

    # update numeric variables
    df.assign do
      assigner = {}
      vectors.each_with_index do |v, i|
        assigner[keys[i]] = v * -1 if v.numeric?
      end
      assigner
    end
    # =>
    #<RedAmber::DataFrame : 5 x 3 Vectors, 0x0000000000090808>
             index       float      string
    0            0   -0.000000      A     
    1           -1   -1.100000      B     
    2           -2   -2.200000      C     
    3           -3         NaN      D     
    4       (null)      (null)      (null)

    # Or it ’s shorter like this:
    df.assign do
      variables.select.with_object({}) do |(key, vector), assigner|
        assigner[key] = vector * -1 if vector.numeric?
      end
    end
    # => same as above
    ```

- Key type

  Symbol key and String key are considered as the same key.

## Updating

### `sort`

  `sort` accepts parameters as sort_keys thanks to the amazing Red Arrow feature。
    - :key, "key" or "+key" denotes ascending order
    - "-key" denotes descending order

  ```ruby
  df = RedAmber::DataFrame.new({
        index:  [1, 1, 0, nil, 0],
        string: ['C', 'B', nil, 'A', 'B'],
        bool:   [nil, true, false, true, false],
      })
  df.sort(:index, '-bool').tdr(tally: 0)
  # =>
  #<RedAmber::DataFrame : 5 x 3 Vectors, 0x00000000000c443c>            
           index  string  bool                                          
  0            0  (null)  false                                         
  1            0  B       false                                         
  2            1  B       true                                          
  3            1  C       (null)                                        
  4       (null)  A       true
  ```

- [ ] Clamp

- [ ] Clear data

## Treat na data

### `remove_nil`

  Remove any observations containing nil.

## Grouping

### `group(aggregating_keys, function, target_keys)`

  (This is a temporary API and may change in the future version.)

  Create grouped dataframe by `aggregation_keys` and apply `function` to each group and returns in `target_keys`. Aggregated key name is `function(key)` style.

  (The current implementation is not intuitive. Needs improvement.)

  ```ruby
  ds = Datasets::Rdatasets.new('dplyr', 'starwars')
  starwars = RedAmber::DataFrame.new(ds.to_table.to_h)
  starwars.tdr(11)
  # =>
  RedAmber::DataFrame : 87 x 11 Vectors
  Vectors : 3 numeric, 8 strings
  #  key         type   level data_preview
  1  :name       string    87 ["Luke Skywalker", "C-3PO", "R2-D2", "Darth Vader",   "Leia Organa", ... ]
  2  :height     uint16    46 [172, 167, 96, 202, 150, ... ], 6 nils
  3  :mass       double    39 [77.0, 75.0, 32.0, 136.0, 49.0, ... ], 28 nils
  4  :hair_color string    13 ["blond", nil, nil, "none", "brown", ... ], 5 nils
  5  :skin_color string    31 ["fair", "gold", "white, blue", "white", "light", ..  . ]
  6  :eye_color  string    15 ["blue", "yellow", "red", "yellow", "brown", ... ]
  7  :birth_year double    37 [19.0, 112.0, 33.0, 41.9, 19.0, ... ], 44 nils
  8  :sex        string     5 {"male"=>60, "none"=>6, "female"=>16, "hermaphroditic"=>1, nil=>4}
  9  :gender     string     3 {"masculine"=>66, "feminine"=>17, nil=>4}
  10 :homeworld  string    49 ["Tatooine", "Tatooine", "Naboo", "Tatooine", "Alderaan", ... ], 10 nils
  11 :species    string    38 ["Human", "Droid", "Droid", "Human", "Human", ... ], 4 nils

  grouped = starwars.group(:species, :mean, [:mass, :height])
  # =>
  #<RedAmber::DataFrame : 38 x 3 Vectors, 0x000000000000fbf4>
  Vectors : 2 numeric, 1 string
  # key             type   level data_preview
  1 :"mean(mass)"   double    27 [82.78181818181818, 69.75, 124.0, 74.0, 1358.0, ... ], 6 nils
  2 :"mean(height)" double    32 [176.6451612903226, 131.2, 231.0, 173.0, 175.0, ... ]
  3 :species        string    38 ["Human", "Droid", "Wookiee", "Rodian", "Hutt", ... ], 1 nil

  count = starwars.group(:species, :count, :species)[:"count(species)"]
  df = grouped.slice(count > 1)
  # =>
  #<RedAmber::DataFrame : 8 x 3 Vectors, 0x000000000000fc44>
  Vectors : 2 numeric, 1 string
  # key             type   level data_preview
  1 :"mean(mass)"   double     8 [82.78181818181818, 69.75, 124.0, 74.0, 80.0, ... ]
  2 :"mean(height)" double     8 [176.6451612903226, 131.2, 231.0, 208.66666666666666, 173.0, ... ]
  3 :species        string     8 ["Human", "Droid", "Wookiee", "Gungan", "Zabrak", ... ]

  df.table
  # =>
  #<Arrow::Table:0x1165593c8 ptr=0x7fb3db144c70>
	mean(mass)	mean(height)	species
  0	 82.781818	  176.645161	Human  
  1	 69.750000	  131.200000	Droid  
  2	124.000000	  231.000000	Wookiee
  3	 74.000000	  208.666667	Gungan 
  4	 80.000000	  173.000000	Zabrak 
  5	 55.000000	  179.000000	Twi'lek
  6	 53.100000	  168.000000	Mirialan
  7	 88.000000	  221.000000	Kaminoan
  ```

  Available functions are:

  - [ ] all                 
  - [ ] any
  - [ ] approximate_median
  - ✓ count
  - [ ] count_distinct
  - [ ] distinct
  - ✓ max
  - ✓ mean
  - ✓ min
  - [ ] min_max
  - ✓ product
  - ✓ stddev
  - ✓ sum
  - [ ] tdigest
  - ✓ variance

## Combining DataFrames

- [ ]  obs

- [ ] Add vars

- [ ] Inner join

- [ ] Left join

## Encoding

- [ ] One-hot encoding

## Iteration (not impremented)
