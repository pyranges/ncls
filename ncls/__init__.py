
# compilation hack - canna import before it is compiled, but setup.py reads this file methinks
# and errors
try:
    from src.ncls import NCLS
except ImportError:
    pass

from ncls.version import __version__
