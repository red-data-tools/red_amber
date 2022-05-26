# DataFrame

Class RedAmber::DataFrame represents 2D-data table.

## Constructors and saving

- [x] `new` from a columnar Hash

  ```ruby
    RedAmber::DataFrame.new(x: [1, 2, 3])
  ```

- [x] `new` from a schema (by Hash) and rows (by Array)

  ```ruby
    RedAmber::DataFrame.new({:x=>:uint8}, [[1], [2], [3]])
  ```

- [x] `new` from an Arrow::Table


  ```ruby
    table = Arrow::Table.new(x: [1, 2, 3])
    RedAmber::DataFrame.new(table)
  ```

- [x] `new` from a Rover::DataFrame


  ```ruby
    rover = Rover::DataFrame.new(x: [1, 2, 3])
    RedAmber::DataFrame.new(rover)
  ```

- [x] `load` (class method)

     - [x] from a [`.arrow`, `.arrows`, `.csv`, `.csv.gz`, `.tsv`] file
       
    ```ruby
      RedAmber::DataFrame.load("test/entity/with_header.csv")
    ```

     - [x] from a string buffer

     - [x] from a URI

    ```ruby
      uri = URI("https://github.com/heronshoes/red_amber/blob/master/test/entity/with_header.csv")
      RedAmber::DataFrame.load(uri)
    ```

     - [x] from a Parquet file

    ```ruby
      require 'parquet'
      dataframe = RedAmber::DataFrame.load("file.parquet")
    ```

- [x] `save` (instance method)

     - [x] to a [`.arrow`, `.arrows`, `.csv`, `.csv.gz`, `.tsv`] file

     - [x] to a string buffer

     - [x] to a URI

     - [x] to a Parquet file

    ```ruby
      require 'parquet'
      dataframe.save("file.parquet")
    ```

## Properties

- [x] `table`

  Reader of Arrow::Table object inside.

- [x] `size`, `n_obs`, `n_rows`
  
  Returns size of Vector (num of observations).
 
- [x] `n_keys`, `n_vars`, `n_cols`,
  
  Returns num of keys (num of variables).
 
- [x] `shape`
 
  Returns shape in an Array[n_rows, n_cols].
 
- [x] `keys`, `var_names`, `column_names`
  
  Returns key names in an Array.

- [x] `types`
  
  Returns types of vectors in an Array of Symbols.

- [x] `data_types`

  Returns types of vector in an Array of `Arrow::DataType`.

- [x] `vectors`

  Returns an Array of Vectors.

- [x] `to_h`

  Returns column-oriented data in a Hash.

- [x] `to_a`, `raw_records`

  Returns an array of row-oriented data without header. If you need a column-oriented full array, use `.to_h.to_a`

- [x] `schema`

  Returns column name and data type in a Hash.

- [x] `==`
 
- [x] `empty?`

## Output

- [x] `to_s`

- [ ] summary, describe

- [x] `to_rover`

  Returns a `Rover::DataFrame`.

- [x] `ls(limit = 10, tally_level: 5, max_element: 5)`

  - Shows some information about self in a transposed style.
  - `ls_str` returns same info as String.

- [x] `inspect`

```ruby
require 'red_amber'
require 'datasets-arrow'

penguins = Datasets::Penguins.new.to_arrow
puts RedAmber::DataFrame.new(penguins).ls
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

  - tally_level: max level to use tally mode
  - max_element: max num of element to show values in each row

## Selecting

- [x] Select columns by `[]` as `[key]`, `[keys]`, `[keys[index]]`
  - Key in a Symbol: `df[:symbol]`
  - Key in a String: `df["string"]`
  - Keys in an Array: `df[:symbol1, "string", :symbol2]`
  - Keys in indeces: `df[df.keys[0]`, `df[df.keys[1,2]]`, `df[df.keys[1..]]`
  - Keys in a Range:
    A end-less Range can be used to represent keys.

```ruby
hash = {a: [1, 2, 3], b: %w[A B C], c: [1.0, 2, 3]}
df = RedAmber::DataFrame.new(hash)
df[:b..:c, "a"]
# =>
#<RedAmber::DataFrame : 3 x 3 Vectors, 0x000000000000b02c>
Vectors : 2 numeric, 1 string            
# key type   level data_preview         
1 :b  string     3 ["A", "B", "C"]      
2 :c  double     3 [1.0, 2.0, 3.0]      
3 :a  uint8      3 [1, 2, 3]
```

- [x] Select rows by `[]` as `[index]`, `[range]`, `[array]`
  - Select a row by index: `df[0]`
  - Select rows by indeces in a Range: `df[1..2]`
  - Select rows by indeces in an Array: `df[1, 2]`
  - Mixed case: `df[2, 0..]`

- [x] Select rows from top or bottom

  `head(n=5)`, `tail(n=5)`, `first(n=1)`, `last(n=1)`

- [ ] slice

## Updating

- [ ] Add a new column

- [ ] Update a single element

- [ ] Update multiple elements

- [ ] Update all elements

- [ ] Update elements matching a condition

- [ ] Clamp

- [ ] Delete columns

- [ ] Rename a column

- [ ] Sort rows

- [ ] Clear data

## Treat na data

- [ ] Drop na (NaN, nil)

- [ ] Replace na with value

- [ ] Interpolate na with convolution array

## Combining DataFrames

- [ ] Add rows

- [ ] Add columns

- [ ] Inner join

- [ ] Left join

## Encoding

- [ ] One-hot encoding

## Iteration (not impremented)

## Filtering (not impremented)
