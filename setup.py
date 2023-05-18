import os

from setuptools import Extension
from distutils.core import setup


dir_path = os.path.dirname(os.path.realpath(__file__))

include_dirs = [dir_path + "/ncls/src", dir_path]

extensions = [
    Extension(
        "ncls.src.ncls",
        ["ncls/src/ncls.pyx", "ncls/src/intervaldb.c"],
        # define_macros=macros,
        include_dirs=include_dirs,
    ),
    Extension(
        "ncls.src.ncls32",
        ["ncls/src/ncls32.pyx", "ncls/src/intervaldb32.c"],
        # define_macros=macros,
        include_dirs=include_dirs,
    ),
    Extension(
        "ncls.src.fncls",
        ["ncls/src/fncls.pyx", "ncls/src/fintervaldb.c"],
        # define_macros=macros,
        include_dirs=include_dirs,
    ),
]

from Cython.Build import cythonize

ext_modules = cythonize(extensions, language_level=2)


setup(ext_modules=ext_modules)
