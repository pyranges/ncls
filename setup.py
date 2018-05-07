from distutils.core import setup
from setuptools import find_packages, Extension, Command
from Cython.Build import cythonize

import os
import sys

from ncls.version import __version__


CLASSIFIERS = """
Development Status :: 5 - Production/Stable
Operating System :: MacOS :: MacOS X
Operating System :: Microsoft :: Windows :: Windows NT/2000
Operating System :: OS Independent
Operating System :: POSIX
Operating System :: POSIX :: Linux
Operating System :: Unix
Programming Language :: Python
Topic :: Scientific/Engineering
Topic :: Scientific/Engineering :: Bio-Informatics
"""

# split into lines and filter empty ones
CLASSIFIERS = filter(None, CLASSIFIERS.splitlines())

# extension sources

extensions = [Extension("src.ncls", ["src/ncls.pyx", "src/intervaldb.c"])]


setup(
    name = "ncls",
    version=__version__,
    packages=find_packages(),
    ext_modules = cythonize(extensions),
    # py_modules=["pyncls"],
    description = \
    'A wrapper for the nested containment list data structure.',
    long_description = __doc__,
    # I am the maintainer; the datastructure was invented by
    # Alexander V. Alekseyenko and Christopher J. Lee.
    author = "Endre Bakken Stovner",
    author_email='endrebak85@gmail.com',
    url = 'https://github.com/endrebak/pyncls',
    license = 'New BSD License',
    classifiers = CLASSIFIERS,
    package_data={'': ['*.pyx', '*.pxd', '*.h', '*.c']},
    include_dirs=[".", "src/"],
)
