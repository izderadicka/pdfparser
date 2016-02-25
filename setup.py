from __future__ import print_function
from distutils.core import setup, Extension
import os,sys
try:
    from Cython.Build import cythonize
    
except ImportError:
    print('You need to install cython first - sudo pip install cython', file=sys.stderr)
    sys.exit(1)

POPPLER_ROOT=os.environ.get('POPPLER_ROOT',os.path.join(os.path.dirname(__file__), 'poppler_src'))
POPPLER_LIB_DIR= os.path.join(POPPLER_ROOT, 'poppler/.libs/')

poppler_ext=Extension('pdfparser.poppler', ['pdfparser/poppler.pyx'], language='c++',
                      extra_compile_args=[],
                      include_dirs=[POPPLER_ROOT, os.path.join(POPPLER_ROOT, 'poppler')],
                      library_dirs=[POPPLER_LIB_DIR],
                      runtime_library_dirs=['$ORIGIN'],
                      libraries=['poppler']) #,  define_macros, undef_macros, library_dirs, libraries, runtime_library_dirs, extra_objects, , extra_link_args, export_symbols, swig_opts, depends
setup(name = 'pdfparser',
      version = '0.1',
      packages=['pdfparser'],
      ext_modules=cythonize(poppler_ext))