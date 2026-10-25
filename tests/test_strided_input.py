import numpy as np
import pytest

from ncls import NCLS


def strided(values, dtype):
    # A column of a row-major 2D array, as pandas >= 3.1 can return from Series.values.
    block = np.zeros((len(values), 3), dtype=dtype)
    block[:, 1] = values
    column = block[:, 1]
    assert not column.flags.c_contiguous
    return column


@pytest.mark.parametrize("dtype", [np.int64, np.int32])
def test_queries_accept_strided_input(dtype):
    starts, ends, ids = [1, 5, 9], [3, 7, 11], [0, 1, 2]
    query_starts, query_ends, query_ids = [2, 8], [6, 9], [10, 11]

    contiguous = NCLS(np.array(starts, dtype=dtype), np.array(ends, dtype=dtype), np.array(ids, dtype=np.int64))
    ncls = NCLS(strided(starts, dtype), strided(ends, dtype), strided(ids, np.int64))
    assert ncls.intervals() == contiguous.intervals()

    queries = (strided(query_starts, dtype), strided(query_ends, dtype), strided(query_ids, np.int64))
    expected_queries = tuple(np.array(a, dtype=t) for a, t in zip(queries, (dtype, dtype, np.int64)))
    for method in ("all_overlaps_both", "first_overlap_both", "has_overlaps", "all_containments_both"):
        got = getattr(ncls, method)(*queries)
        want = getattr(contiguous, method)(*expected_queries)
        assert np.array_equal(np.asarray(got), np.asarray(want)), method
