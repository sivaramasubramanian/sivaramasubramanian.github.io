---
layout: post
title:  "BRIN index in Postgres"
date:   2022-07-24 17:07:41 +0530
description: This post explains about BRIN indexes in Postgres with its pros and cons
tags: postgres indexing brin
excerpt_separator: <!--more-->
---

One of the key features of Postgres is its ability to index data using many different types of indexes, each with its own set of benefits and drawbacks. One type of index that is particularly useful for large tables is the BRIN index. 
<!--more-->
### What are BRIN Indexes?
BRIN stands for "Block Range INdex". BRIN indexes work by dividing the table into blocks and storing the minimum and maximum values for each block. This allows Postgres to quickly identify which blocks contain the desired data and only scan those blocks, reducing the overall time and resources required for the query. This also allows the index to be much smaller in size, which makes it more efficient to use.

### When should we use BRIN indexes?
BRIN indexes are particularly useful for tables that have a large number of rows with a high degree of data correlation within blocks of pages. For example, a BRIN index would be well-suited for a column that contains time-series data, where each value represents a single point in time and the insertion order is correlated to the physical storage order, i.e., there won't be many overlaps in min and max values between pages.


### Creating a BRIN index
To create a BRIN index in Postgres, you can use the CREATE INDEX command. Here is an example of how to create a BRIN index on a table named my_table:

```sql
CREATE INDEX my_index
ON my_table
USING BRIN (column1);
```

### Performance Comparison
To compare the performance between Btree and BRIN indexes, we can create a table and fill it with some random data.

I used the following query to insert 10 million rows, this uses a few UDFs to generate random integers and timestamps.

```sql
INSERT INTO brin_test (
    SELECT i as id,
     (i * 1.5)::int as strict_inc,
    random_int_between(1, 10000000) as random,
    random_int_between(i, i + 5) as inc_with_fluctuations,
    random_int_between(i, i + 5000) as inc_with_large_flucts,
    ('2022-01-01'::timestamp + (i * interval '1 second')) as strict_inc_time,
    random_time_between('1970-01-01', '2022-01-01') as random_time,
    random_time_between('2022-01-01'::timestamp + (i * interval '1 second'), '2022-01-01'::timestamp + (i * interval '1 second' + interval '10 second')) inc_time_with_fluctuations,
    random_time_between('2022-01-01'::timestamp + (i * interval '1 second'), '2022-01-01'::timestamp + (i * interval '1 second' + interval '1 month')) inc_time_with_large_flucts,
    from generate_series(1, 10000000) as i
);
```
- `strict_inc` and `strict_inc_time` have strictly increasing values but may contain duplicates.
- `random` and `random_time` contain fully random values.
- `inc_with_fluctuations` and `inc_time_with_fluctuations` contain generally increasing values with slight fluctuations.
- `inc_with_large_flucts` and `inc_time_with_large_flucts` contain generally increasing values with large fluctuations.

After data insertion, the table looks like this,

| id | strict_inc | random  | inc with_fluctations |   strict_inc_time&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;   |        random_time&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;         | inc_time_with_fluctuations | inc with_large_flucts | inc_time_with_large_flucts |
|----|------------|---------|---------|------------------------------------|----------------------------|----------------------------|-----------------------|----------------------------|
|  1 | 2 | 7909441 |   2 | 2022-01-01 00:00:01 | 2017-04-24 21:08:09.98 | 2022-01-01 00:00:10.77 |3741 | 2022-01-19 23:31:36.72 |
|  2 | 3 | 2654424 |   5 | 2022-01-01 00:00:02 | 2014-10-27 20:32:44.45 | 2022-01-01 00:00:08.86 |4568 | 2022-01-18 08:14:47.08 |
|  3 | 5 | 1617074 |   4 | 2022-01-01 00:00:03 | 2001-09-28 23:49:05.66 | 2022-01-01 00:00:12.68 |4847 | 2022-01-22 08:10:27.84 |
|  4 | 6 | 7145184 |   7 | 2022-01-01 00:00:04 | 1973-08-10 17:16:05.11  | 2022-01-01 00:00:11.9 |3630 | 2022-01-06 07:04:08.76 |
|  5 | 8 | 8897237 |   7 | 2022-01-01 00:00:05 | 2012-12-26 03:56:10.39 | 2022-01-01 00:00:09.65 |4341 | 2022-01-22 13:38:50.03 |
|  6 | 9 | 1357535 |   9 | 2022-01-01 00:00:06 | 2004-09-10 10:14:19.94 | 2022-01-01 00:00:13.54 |3571 | 2022-01-01 16:28:10.77 |
|  7 |11 | 8036526 |   7 | 2022-01-01 00:00:07 | 1976-04-18 13:52:20.69 | 2022-01-01 00:00:11.67 |2159 | 2022-01-30 05:03:33.79 |
|  8 |12 | 6248973 |   8 | 2022-01-01 00:00:08 | 1988-03-27 00:46:22.00 | 2022-01-01 00:00:12.15 |1202 | 2022-01-24 00:41:01.77 |
|  9 |14 | 2993551 |  10 | 2022-01-01 00:00:09 | 1990-06-07 14:07:25.84 | 2022-01-01 00:00:14.64 |1120 | 2022-01-12 00:54:51.17 |
| 10 |15 | 8377196 |  11 | 2022-01-01 00:00:10 | 1983-01-19 04:26:23.50 | 2022-01-01 00:00:19.99 | 323 | 2022-01-09 20:10:27.66 |

In this table, I ran SELECT queries with both single values in the WHERE clause and also a range with BETWEEN ... AND in the WHERE clause,

|  Query Type  |  No index |  Btree | BRIN  |
|-------------------------------------------|---|---|---|
| Single Row Lookup on strictly increasing int  | 239.246  | 1.291  | 2.629  |
| Single Row Lookup on random int | 229.026  | 2.876  | 2385.987  |
| Single Row Lookup on increasing int with fluctuations | 224.503  |  12.302 | 5.632  |
| Single Row Lookup on increasing int with large fluctuations | 381.571 | 1.684 | 2.542 |
| Single Row Lookup on strictly increasing timestamp  | 268.229  |  2.611 | 0.271  |
| Single Row Lookup on random timestamp | 254.684  | 2.582  |  1355.999 |
| Single Row Lookup on increasing timestamp with fluctuations | 286.124  | 3.473  |  0.303 |
| Single Row Lookup on increasing timestamp with large fluctuations | 385.281 | 0.133 | 155.888 |
| Range query on strictly increasing int  | 269.887  | 55.806 |  2.464 |
| Range query on random int  | 303.607  | 69.201 | 223.032  |
| Range query on increasing int with fluctuations  | 256.515  | 55.493  |  4.731 |
| Range query on increasing int with large fluctuations | 388.501 | 27.386 | 51.219 |
| Range query on strictly increasing timestamp  | 272.902  | 58.897  |  59.066 |
| Range query on random timestamp  | 280.474  |  7.231 | 374.964  |
| Range query on increasing timestamp with fluctuations  | 299.144  | 58.038  | 65.234  |
| Range query on increasing timestamp with large fluctuations | 2045.531 | 52.623 | 498.498 |


From the results, we can see,
- Btree provides consistent performance regardless of data order.
- BRIN index performs best when the data is strictly increasing or when the data has only slight fluctuations. It is 2x better on single-row queries and up to 25x faster on range queries.
- BRIN is 500-1000x slower than Btree when data is random.
- When there are large fluctuations in data, it is up to 10x slower than BTree.


Understandably, BRIN performs worse than Btree on random data and data with large fluctuations, since it cannot use the min-max values to skip blocks entirely in such data sets.

### Block size in BRIN index
When creating a BRIN index, we can provide the number of blocks that must be summarized in a single range.
```sql
create index brin_test_idx2
 on brin_test
using BRIN(strict_inc) with (pages_per_range = 16);
```
This creates a BRIN index which contains a summary entry for every 16 pages.

It's important to consider the block size. The default block size is typically a good starting point, but you can experiment with different sizes to see which provides the best performance for your specific use case based on fluctuations in your data.

The tradeoff is that with smaller `pages_per_range` values, there will be more summary tuples, increasing the index size and the chance of heavy overlap between blocks, making the min-max summary useless, especially if the table is wide. But with larger `pages_per_range` values, there will be fewer blocks, but once a matching block is identified, we have to scan through more data to find the exact matches.

In conclusion, BRIN is a powerful index type for specific data patterns where the data ordering closely resembles the physical ordering of the blocks on disk. But in other cases, using normal Btree indexes will be better.
