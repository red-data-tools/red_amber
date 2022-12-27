# @markup markdown

# Comparison of DataFrames

Compare basic features ofRedAmber with Python 
[Pandas](https://pandas.pydata.org/),
R [Tidyverse](https://www.tidyverse.org/) and
Julia [Dataframes](https://dataframes.juliadata.org/stable/).

## Select columns (variables)

| Features                        |	RedAmber        |	Tidyverse 	                     | Pandas                                 | DataFrames.jl |
|---                              |---              |---                               |---                                     |---            |
| Select columns as a dataframe   |	pick, drop, [] 	| dplyr::select, dplyr::select_if  | [], loc[], iloc[], drop, select_dtypes | [], select    |
| Select a column as a vector     | 	[], v 	      | dplyr::pull, [, x]	             | [], loc[], iloc[]                      | [!, :x]|
| Move columns to a new position  |	pick, [] 	      | relocate                         | [], reindex, loc[], iloc[]             | |

## Select rows (records, observations)

| Features                                              |	RedAmber 	        | Tidyverse                   | Pandas                   | DataFrames.jl |
|---                                                    |---                |---                          |---                       |---            |
| Select rows that meet logical criteria as a dataframe |	slice, remove, [] | 	dplyr::filter             |	[], filter, query, loc[] | 
| Select rows by position as a dataframe 	              | slice, remove, [] | dplyr::slice 	              | iloc[], drop             |
| Move rows to a new position 	                        | slice, [] 	      | dplyr::filter, dplyr::slice |	reindex, loc[], iloc[]   |

## Update columns / create new columns

|Features 	                        | RedAmber 	          | Tidyverse 	                                        | Pandas            | DataFrames.jl |
|---                                |---                  |---                                                  |---                |---            |
| Update existing columns           |	assign 	            | dplyr::mutate                                      	| assign, []=       |               |
| Create new columns 	              | assign, assign_left |	dplyr::mutate 	                                    | apply             |               |
| Compute new columns, drop others 	| new 	              | transmute 	                                        | (dfply:)transmute |               |
| Rename columns 	                  | rename              |	dplyr::rename, dplyr::rename_with, purrr::set_names |	rename, set_axis  |               |
| Sort dataframe 	                  | sort 	              | dplyr::arrange 	                                    | sort_values       |               |

## Reshape dataframe

| Features 	                                           | RedAmber 	| Tidyverse 	        | Pandas       | DataFrames.jl |
|---                                                   |---         |---                  |---           |---            |
| Gather columns into rows (create a longer dataframe) |	to_long 	| tidyr::pivot_longer |	melt         |               |
| Spread rows into columns (create a wider dataframe)  | to_wide 	  | tidyr::pivot_wider 	| pivot        |               |
| transpose a wide dataframe 	                         | transpose 	| transpose, t 	      | transpose, T |               |

## Grouping

| Features 	| RedAmber 	              | Tidyverse 	                          | Pandas       | DataFrames.jl |
|---        |---                      |---                                    |---           |---            |
|Grouping 	| group, group.summarize 	| dplyr::group_by %>% dplyr::summarise 	| groupby.agg  |               |

## Combine dataframes or tables

| Features 	                               |  RedAmber 	                    | Tidyverse          | Pandas  | DataFrames.jl |
|---                                       |---                             |---                 |---      |---            |
| Combine additional columns               | merge, bind_cols               | dplyr::bind_cols   | concat  |               |
| Combine additional rows 	               | concatenate, concat, bind_rows |	dplyr::bind_rows 	 | concat  |               |
| Inner join                               | join, inner_join 	            | dplyr::inner_join  | merge   |               |
| Full join                                | join, full_join, outer_join 	  | dplyr::full_join   | merge   |               |
| Left join 	                             | join, left_join                |	dplyr::left_join 	 | merge   |               |
| Right join                               | join, right_join               |	dplyr::right_join  | merge   |               |
| Semi join 	                             | join, semi_join 	              | dplyr::semi_join 	 | [isin]  |               |
| Anti join 	                             | join, anti_join                |	dplyr::anti_join 	 | [isin]  |               |
| Collect rows that appear in x or y       | union 	                        | dplyr::union       | merge   |               |
| Collect rows that appear in both x and y | intersect 	                    | dplyr::intersect 	 | merge   |               |
| Collect rows that appear in x but not y  | difference, setdiff 	          | dplyr::setdiff 	   | merge   |               |

 

