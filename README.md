# Nested containment list

[![Build Status](https://travis-ci.org/hunt-genes/ncls.svg?branch=master)](https://travis-ci.org/hunt-genes/ncls) [![PyPI version](https://badge.fury.io/py/ncls.svg)](https://badge.fury.io/py/ncls)

The Nested Containment List is a datastructure for interval overlap queries,
like the interval tree. It is usually an order of magnitude faster than the
interval tree both for building and query lookups.

The implementation here is a revived version of the one used in the now defunct
PyGr library, which died of bitrot. I have made it less memory-consuming and
created wrapper functions which allows batch-querying the NCLS for further speed
gains.

It was implemented to be the cornerstone of the PyRanges project, but I have made
it available to the Python community as a stand-alone library. Enjoy.

Paper: https://academic.oup.com/bioinformatics/article/23/11/1386/199545

## Install

```
pip install ncls
```

## Usage

```python
# see the examples/ folder for more examples
from ncls import NCLS

import pandas as pd

starts = pd.Series(range(0, 5))
ends = starts + 100
ids = starts

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

# everything done in C/Cython; faster
ncls.all_overlaps_both(starts_query.values, ends_query.values, indexes_query.values)
# (array([10000, 10000, 10000, 10000, 10000,   100,   100,   100,   100,
#          100]), array([0, 1, 2, 3, 4, 0, 1, 2, 3, 4]))

# return intervals in python (slow/mem-consuming)
intervals = ncls.intervals()
intervals
# [(0, 100, 0), (1, 101, 1), (2, 102, 2), (3, 103, 3), (4, 104, 4)]
```

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

## Citation

> Alexander V. Alekseyenko, Christopher J. Lee; Nested Containment List (NCList): a new algorithm for accelerating interval query of genome alignment and interval databases, Bioinformatics, Volume 23, Issue 11, 1 June 2007, Pages 1386–1393, https://doi.org/10.1093/bioinformatics/btl647
