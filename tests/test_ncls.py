from ncls import NCLS
import pandas as pd

from time import gmtime, strftime
import psutil

def mem():
	print(str(round(psutil.Process().memory_info().rss/1024./1024., 2)) + ' MB')

for i in range(0, int(1e6)):

    if i % int(1e4) == 0:
        print("\n")
        print(i)
        print(strftime("%Y-%m-%d %H:%M:%S", gmtime()))
        print(mem())

    starts = pd.Series(range(0, 50))
    ends = starts + 2
    ids = starts

    ncls = NCLS(starts.values, ends.values, ids.values)
    # ncls2 = NCLS(starts.values, ends.values, ids.values)

    xs, xo = ncls.all_overlaps_both(starts.values, ends.values, ids.values)
    # xs, xo = ncls.has_overlap(starts.values, ends.values, ids.values)

    # print(xs, xo)
    # raise
