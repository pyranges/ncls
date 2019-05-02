from ncls import NCLS

import numpy as np


ncls = NCLS()

ncls.append(1,2,1)
ncls.append(3,4,3)
ncls.append(5,7,5)

ncls.build()

starts2 = np.array([1,7])
ends2 = np.array([2,8])
indexes2 = np.array([11,22])

print(ncls.has_overlaps(starts2, ends2, indexes2))

print(ncls.intervals())
print(ncls.find_overlap(1,3))

for i in ncls.find_overlap(1,4):
    print(i)
