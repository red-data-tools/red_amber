# TDR (Transposed DataFrame Representation)

([Japanese version](tdr_ja.md) of this document is available)

TDR is a presentation style of 2D data. It shows columnar vector values in *row Vector* and observations in *column* just like a **transposed** table.

![TDR Image](image/tdr.png) 

Row-oriented data table (1) and columnar data table (2) have different data allocation in memory within a context of Arrow Columnar Format. But they have the same data placement (in rows and columns) in our brain.

TDR (3) is a logical concept of data placement to transpose rows and columns in a columnar table (2).

![TDR and Table Image](image/tdr_and_table.png)

TDR is not an implementation in software but a logical image in our mind.

TDR is consistent with the 'transposed' tidy data concept. The only thing we should do is not to use the positional words 'row' and 'column'.

![tidy data in TDR](image/tidy_data_in_TDR.png)

TDR is one of a simple way to create DataFrame object in many libraries. For example, we can initalize Arrow::Table in Red Arrow like the right below and get table as left.

![Arrow Table New](image/arrow_table_new.png)

We are using TDR style code naturally. For other example:
  - Ruby: Daru::DataFrame, Rover::DataFrame accept same arguments.
  - Python: similar style in Pandas for pd.DataFrame(data_in_dict)
  - R: similar style in tidyr for tibble(x = 1:3, y = c("A", "B", "C"))

There are other ways to initialize data frame, but they are not intuitive.

## Table and TDR API

The API based on TDR is draft and RedAmber is a small experiment to test the TDR concept. The following is a comparison of Table and TDR (draft).

|     |Basic Table|Transposed DataFrame|Comment for TDR|
|-----------|---------|------------|---|
|name in TDR|`Table`|`TDR`|**T**ransposed **D**ataFrame **R**epresentation|
|variable   |located in a column|a key and a `Vector` in lateral|select by key|
|observation|located in a row|intersection in a vertical axis|select by index|
|number of rows|n_rows etc. |`size` |`n_row` is available as an alias|
|number of columns|n_columns etc. |`n_keys`  |`n_col` is available as an alias|
|shape      |[n_rows, n_columns]  |`[size, n_keys]` |same order as Table|
|merge/join left| left_join(a,b)<br>merge(a, b, how='left')|`a.join(b)` |naturally join from bottom|
|merge/join right| right_join(a,b))<br>merge(a, b, how='right')|`b.join(a)` |naturally join from bottom|

## Q and A for TDR

（Not prepared yet)
