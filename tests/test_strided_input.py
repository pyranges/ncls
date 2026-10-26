import numpy as np
import pytest

from ncls import FNCLS, NCLS


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


@pytest.mark.parametrize("dtype", [np.int64, np.int32])
@pytest.mark.parametrize("reverse", [False, True])
def test_constructor_owns_data_from_readonly_views(dtype, reverse):
    starts = strided([1, 5, 9], dtype)
    ends = strided([3, 7, 11], dtype)
    ids = strided([0, 1, 2], np.int64)
    arrays = [a[::-1] if reverse else a for a in (starts, ends, ids)]
    expected = NCLS(*(a.copy() for a in arrays)).intervals()
    for a in arrays:
        a.flags.writeable = False
    tree = NCLS(*arrays)
    for a in arrays:
        a.flags.writeable = True
        a[:] = 0
    assert tree.intervals() == expected


@pytest.mark.parametrize("dtype", [np.int64, np.int32])
def test_constructor_converts_mismatched_end_and_id_dtypes(dtype):
    tree = NCLS(np.array([1, 5], dtype=dtype), np.array([3, 7], dtype=np.int16), np.array([10, 11], dtype=np.int32))
    assert tree.intervals() == [(1, 3, 10), (5, 7, 11)]


def test_float_constructor_owns_data_from_readonly_views():
    arrays = [strided([1, 5, 9], np.double), strided([3, 7, 11], np.double), strided([0, 1, 2], np.int64)]
    query = (np.array([2.0, 6.0]), np.array([4.0, 8.0]), np.array([10, 11], dtype=np.int64))
    expected = FNCLS(*(a.copy() for a in arrays)).all_overlaps_both(*query)
    for a in arrays:
        a.flags.writeable = False
    tree = FNCLS(*arrays)
    for a in arrays:
        a.flags.writeable = True
        a[:] = 0
    actual = tree.all_overlaps_both(*query)
    for got, want in zip(actual, expected):
        np.testing.assert_array_equal(got, want)
