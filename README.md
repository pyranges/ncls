# Nested containment list

## Deprecation notice

While I'll continue maintaining this library I suggest you change to [ruranges](https://github.com/pyranges/ruranges/) which is a more lightweight and faster library with many more operations than NCLS.

## NCLS

[![Build Status](https://travis-ci.org/biocore-ntnu/ncls.svg?branch=master)](https://travis-ci.org/hunt-genes/ncls) [![PyPI version](https://badge.fury.io/py/ncls.svg)](https://badge.fury.io/py/ncls)

The Nested Containment List is a datastructure for interval overlap queries,
like the interval tree. It is usually an order of magnitude faster than the
interval tree both for building and query lookups.

The implementation here is a revived version of the one used in the now defunct
PyGr library, which died of bitrot. I have made it less memory-consuming and
created wrapper functions which allows batch-querying the NCLS for further speed
gains.

It was implemented to be the cornerstone of the PyRanges project, but I have made
it available to the Python community as a stand-alone library. Enjoy.

Original Paper: https://academic.oup.com/bioinformatics/article/23/11/1386/199545
Cite: http://dx.doi.org/10.1093/bioinformatics/btz615

## Cite

If you use this library in published research cite

http://dx.doi.org/10.1093/bioinformatics/btz615

## Install

```
pip install ncls
```

## Usage

```python
from ncls import NCLS

import pandas as pd

starts = pd.Series(range(0, 5))
ends = starts + 100
ids = starts

subject_df = pd.DataFrame({"Start": starts, "End": ends}, index=ids)

print(subject_df)
#    Start  End
# 0      0  100
# 1      1  101
# 2      2  102
# 3      3  103
# 4      4  104

ncls = NCLS(starts.values, ends.values, ids.values)

# python API, slower
it = ncls.find_overlap(0, 2)
for i in it:
    print(i)
# (0, 100, 0)
# (1, 101, 1)

starts_query = pd.Series([1, 3])
ends_query = pd.Series([52, 14])
indexes_query = pd.Series([10000, 100])

query_df = pd.DataFrame({"Start": starts_query.values, "End": ends_query.values}, index=indexes_query.values)

query_df
#        Start  End
# 10000      1   52
# 100        3   14


# everything done in C/Cython; faster
l_idxs, r_idxs = ncls.all_overlaps_both(starts_query.values, ends_query.values, indexes_query.values)
l_idxs, r_idxs
# (array([10000, 10000, 10000, 10000, 10000,   100,   100,   100,   100,
#          100]), array([0, 1, 2, 3, 4, 0, 1, 2, 3, 4]))

print(query_df.loc[l_idxs])
#        Start  End
# 10000      1   52
# 10000      1   52
# 10000      1   52
# 10000      1   52
# 10000      1   52
# 100        3   14
# 100        3   14
# 100        3   14
# 100        3   14
# 100        3   14
print(subject_df.loc[r_idxs])
#    Start  End
# 0      0  100
# 1      1  101
# 2      2  102
# 3      3  103
# 4      4  104
# 0      0  100
# 1      1  101
# 2      2  102
# 3      3  103
# 4      4  104

# return intervals in python (slow/mem-consuming)
intervals = ncls.intervals()
intervals
# [(0, 100, 0), (1, 101, 1), (2, 102, 2), (3, 103, 3), (4, 104, 4)]
```

There is also an experimental floating point version of the NCLS called FNCLS.
See the examples folder.

## Benchmark

Test file of 100 million intervals (created by subsetting gencode gtf with replacement):

| Library | Function | Time (s) | Memory (GB) |
| --- | --- | --- | --- |
| bx-python | build | 161.7 | 2.5 |
| ncls | build | 3.15 | 0.5 |
| bx-python | overlap | 148.4 | 4.3 |
| ncls | overlap | 7.2 | 0.5 |

Building is 50 times faster and overlap queries are 20 times faster. Memory
usage is one fifth and one ninth.

## Original paper

> Alexander V. Alekseyenko, Christopher J. Lee; Nested Containment List (NCList): a new algorithm for accelerating interval query of genome alignment and interval databases, Bioinformatics, Volume 23, Issue 11, 1 June 2007, Pages 1386–1393, https://doi.org/10.1093/bioinformatics/btl647
