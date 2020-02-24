from ncls.src.ncls import NCLS64
from ncls.src.ncls32 import NCLS32

import numpy as np

def NCLS(starts, ends, ids):

    if starts.dtype == np.int64:
        return NCLS64(starts, ends, ids)
    elif starts.dtype == np.int32:
        return NCLS32(starts, ends, ids)
    else:
        raise Exception("Starts/Ends not int64 or int32: " + str(starts.dtype))


def FNCLS(starts, ends, ids):

    from ncls.src.fncls import FNCLS

    if starts.dtype == np.double:
        return FNCLS(starts, ends, ids)
    else:
        raise Exception("Starts/Ends not double: " + str(starts.dtype))

from ncls.version import __version__
