
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

    ncls = NCLS(starts, ends, ids)
    print(ncls)
    print(ncls.intervals())

    assert list(ncls.find_overlap(0, 2)) == []
    print("aaa", list(ncls.find_overlap(9_223_372_036_854_775_805, 9_223_372_036_854_775_806)))
    assert list(ncls.find_overlap(0, 9_223_372_036_854_775_806)) == [(5, 6, 2147483647), (9223372036854775805, 9223372036854775807, 3)]

    r, l = ncls.all_overlaps_both(starts, ends, ids)
    assert list(r) == [2147483647, 3]
    assert list(l) == [2147483647, 3]


def test_all_containments_both():

    starts = np.array([1291845632, 3002335232], dtype=int)
    ends = np.array([1292894207, 3002597375], dtype=int)
    ids = np.array([0, 1], dtype=int)

    ncls = NCLS(starts, ends, ids)
    subs, covers = ncls.all_containments_both(starts, ends, ids)

    print(ncls.intervals())

    assert list(subs) == [0, 1] == list(covers)


