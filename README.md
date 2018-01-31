pdfparser
---------

Python binding for libpoppler - focused on text extraction from PDF documents.

Intended as an easy to use replacement for [pdfminer](https://github.com/euske/pdfminer), 
which provides much better performance (see below for short comparison) and is Python3 compatible.

See this [article](http://zderadicka.eu/parsing-pdf-for-fun-and-profit-indeed-in-python/)
for some comparisons with pdfminer and other approaches. 


Binding is written in [cython](http://cython.org/).

Requires recent libpoppler >= 0.40 - so I'd recommend to build it from source to get latest library, 
but it works also with recent libpoppler library present in common linux distributions (then it requires 
dev package to build). See below for installation instructions.


Available under GPL v3 or any later version license (libpoppler is also GPL).

## How to install

Below or some instructions to install this package

### CentOS 7 - system-wide libpoppler (pkg-config method)

Install the poppler-devel package (Tested with version 0.26.5-16.el7)

    yum install poppler-devel poppler-cpp-devel

Install cython
    
    pip install cython

Install the repo
    
    pip install git+https://github.com/izderadicka/pdfparser

### CentOS 7 - self compiled method

Clone this repo and enter into the root folder

    cd /git/repos/
    git clone https://github.com/izderadicka/pdfparser.git
    cd pdfparser

Clone the poppler repo and install (similar to build_poppler.sh)
    
    yum install openjpeg2-devel libjpeg-turbo-devel cmake
    git clone --depth 1 https://anongit.freedesktop.org/git/poppler/poppler.git poppler_src
    cd poppler_src
    cmake -DENABLE_SPLASH=OFF -DENABLE_UTILS=OFF -DENABLE_LIBOPENJPEG=none .
    make
    cp libpoppler.so.?? ../pdfparser/
    cp cpp/libpoppler-cpp.so.? ../pdfparser
    cd ..
    POPPLER_ROOT=poppler_src python setup.py install
    
 
### Debian like - self compiled method (with local poppler library)
 
```
git clone --depth 1 https://github.com/izderadicka/pdfparser.git
cd pdfparser
./build_poppler.sh
pip install cython
POPPLER_ROOT=poppler_src ./setup.py install
#test that it works
python tests/dump_file.py test_docs/test1.pdf
```

### Debian like -  system wide libpoppler 
```
sudo apt-get update
sudo apt-get install -y libpoppler-private-dev libpoppler-cpp-dev
pip install cython
pip install git+https://github.com/izderadicka/pdfparser
```

### Mac OS
```
pip install cython
pip install git+https://github.com/izderadicka/pdfparser
```
    

## Speed comparisons

|                             | pdfreader     | pdfminer      |speed-up factor|
| --------------------------- | ------------- | ------------- |---------------|
| tiny document (half page)   | 0.033s        | 0.121s        | 3.6 x         |
| small document (5 pages)    | 0.141s        | 0.810s        | 5.7 x         |
| medium document (55 pages)  | 1.166s        | 10.524s       | 9.0 x         |       
| large document (436 pages)  | 10.581s       | 108.095s      | 10.2 x        |


pdfparser code used in test

    import pdfparser.poppler as pdf
    import sys
    
    d=pdf.Document(sys.argv[1])
    
    print('No of pages', d.no_of_pages)
    for p in d:
        print('Page', p.page_no, 'size =', p.size)
        for f in p:
            print(' '*1,'Flow')
            for b in f:
                print(' '*2,'Block', 'bbox=', b.bbox.as_tuple())
                for l in b:
                    print(' '*3, l.text.encode('UTF-8'), '(%0.2f, %0.2f, %0.2f, %0.2f)'% l.bbox.as_tuple())
                    #assert l.char_fonts.comp_ratio < 1.0
                    for i in range(len(l.text)):
                        print(l.text[i].encode('UTF-8'), '(%0.2f, %0.2f, %0.2f, %0.2f)'% l.char_bboxes[i].as_tuple(),\
                            l.char_fonts[i].name, l.char_fonts[i].size, l.char_fonts[i].color,)
                    print()
