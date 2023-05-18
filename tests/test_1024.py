#!/usr/bin/env python

import numpy as np

from ncls import NCLS


def test_all_overlaps_both():
    starts = np.array([0], dtype=np.int64)
    ends = np.array([5000], dtype=np.int64)
    ids = np.array([0], dtype=np.int64)

    ncls = NCLS(starts, ends, ids)

    starts2 = np.arange(0, 2048, 2)
    ends2 = np.arange(1, 2048, 2)

    result = ncls.all_overlaps_both(starts2, ends2, starts2)
    assert len(result[0]) == 1024
    print(result[0])

    starts2 = np.arange(0, 2 * 2048, 2)
    ends2 = np.arange(1, 2 * 2048, 2)
    # ncls2 = NCLS(starts2, ends2, starts2)

    result = ncls.all_overlaps_both(starts2, ends2, starts2)
    assert len(result[0]) == 2048
    print(result[0])
