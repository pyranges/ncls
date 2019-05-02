from ncls.src.ncls import NCLS64
from ncls.src.ncls32 import NCLS32

import numpy as np


def NCLS(starts=None, ends=None, ids=None):
    if starts is None or ends is None or ids is None:
        return NCLS64()
    if starts.dtype == np.int64:
        return NCLS64(starts, ends, ids)
    elif starts.dtype == np.int32:
        return NCLS32(starts, ends, ids)



def NCLS32():
    return NCLS32()


from ncls.version import __version__
