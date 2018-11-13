
from ncls import NCLS
import pandas as pd

import numpy as np

starts = np.array([1, 2, 5, 3], dtype=np.long)

ends = starts + np.array([2, 10, 1, 7], dtype=np.long)

print(NCLS(starts, ends, starts))

def test_ncls():
    starts = pd.Series(range(0, int(1e6)))
    ends = starts + 100
    ids = starts

    print(starts, ends, ids)

    ncls = NCLS(starts.values, ends.values, ids.values)

    # starts = pd.Series([0, 4])
    # ends = pd.Series([2, 5])
    # indexes = pd.Series([98, 99])
    print(starts, ends, indexes)
    it = ncls.all_overlaps_both_stack(starts.values, ends.values, indexes.values)
    it2 = ncls.all_overlaps_both(starts.values, ends.values, indexes.values)

    print(it)
    print(it2)
    assert it == it2
    # assert next(it) == (0, 100, 0)


# def test_next_nonoverlapping():
#
#     starts = pd.Series(range(0, 5))
#     ends = starts + 100
#     ids = starts
#
#     ncls = NCLS(starts.values, ends.values, ids.values)
#
#     result = ncls.find_k_next_nonoverlapping(0, 2, 2)
#
#     print(result)
#
#     assert 0
