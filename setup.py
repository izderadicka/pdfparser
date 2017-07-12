#!/usr/bin/env python
from __future__ import print_function
from setuptools import setup, Extension
import sys

try:
    from Cython.Build import cythonize
    
except ImportError:
    print('You need to install cython first - sudo pip install cython', file=sys.stderr)
    sys.exit(1)

import subprocess


# https://gist.github.com/smidm/ff4a2c079fed97a92e9518bd3fa4797c
def pkgconfig(*packages, **kw):
    """
    Query pkg-config for library compile and linking options. Return configuration in distutils
    Extension format.

    Usage:

    pkgconfig('opencv')

    pkgconfig('opencv', 'libavformat')

    pkgconfig('opencv', optional='--static')

    pkgconfig('opencv', config=c)

    returns e.g.

    {'extra_compile_args': [],
     'extra_link_args': [],
     'include_dirs': ['/usr/include/ffmpeg'],
     'libraries': ['avformat'],
     'library_dirs': []}

     Intended use:

     distutils.core.Extension('pyextension', sources=['source.cpp'], **c)

     Set PKG_CONFIG_PATH environment variable for nonstandard library locations.

    based on work of Micah Dowty (http://code.activestate.com/recipes/502261-python-distutils-pkg-config/)
    """
    config = kw.setdefault('config', {})
    optional_args = kw.setdefault('optional', '')
    # { <distutils Extension arg>: [<pkg config option>, <prefix length to strip>], ...}
    flag_map = {'include_dirs': ['--cflags-only-I', 2],
                'library_dirs': ['--libs-only-L', 2],
                'libraries': ['--libs-only-l', 2],
                'extra_compile_args': ['--cflags-only-other', 0],
                'extra_link_args': ['--libs-only-other', 0],
                }
    for package in packages:
        for distutils_key, (pkg_option, n) in flag_map.items():
            items = subprocess.check_output(['pkg-config', optional_args, pkg_option, package]).decode('utf8').split()
            config.setdefault(distutils_key, []).extend([i[n:] for i in items])
    return config


poppler_config = pkgconfig("poppler")
poppler_ext = Extension('pdfparser.poppler', ['pdfparser/poppler.pyx'], language='c++', **poppler_config)


setup(name='pdfparser',
      version='0.1',
      classifiers=[
            # How mature is this project? Common values are
            #   3 - Alpha
            #   4 - Beta
            #   5 - Production/Stable
            'Development Status :: 3 - Alpha',

            # Indicate who your project is intended for
            'Intended Audience :: Developers',
            'Topic :: Software Development :: PDF Parsing',

            'License :: OSI Approved :: GPLv3',

            'Programming Language :: Python :: 3.6',
        ],
      description="python bindings for poppler",
      long_description="Binding for libpoppler with a focus on fast text extraction from PDF documents.",
      keywords='poppler pdf parsing mining extracting',
      url='https://github.com/izderadicka/pdfparser',
      install_requires=['cython', ],
      packages=['pdfparser', ],
      ext_modules=cythonize(poppler_ext))