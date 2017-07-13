Binding for libpoppler - focus on text extration from PDF documents.
Also comparison with other approaches - pdfminer and GObject Introspection binding for libpoppler.

Requires recent libpoppler >= 0.40 - so it's recommended to compile it from source. 
Use script build_poppler.sh to clone and build.
To install system wise:
```
make install
ldconfig
```

Available under GPL v3 or any later version license (libpoppler is also GPL).

## How to install

Below or some instructions to install this package

### CentOS 7 - pkg-config method

Install the poppler-devel package (Tested with version 0.26.5-16.el7)

    yum install poppler-devel

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
    
    yum install openjpeg2-devel libjpeg-turbo-devel
    git clone --depth 1 git://git.freedesktop.org/git/poppler/poppler poppler_src
    cd poppler_src
    ./autogen.sh
    ./configure --disable-poppler-qt4 --disable-poppler-qt5 --disable-poppler-cpp --disable-gtk-test --disable-splash-output --disable-utils
    make
    cp poppler/.libs/libpoppler.so.?? ../pdfparser/
    cd ..
    python setup.py install
    
 
 ### Debian - self compiled method
 
    sh build_poppler.sh
    cd ..
    python setup.py install
    




## Speed comparisons

http://zderadicka.eu/parsing-pdf-for-fun-and-profit-indeed-in-python/


|                             | pdfreader     | pdfminer      |
| --------------------------- | ------------- | ------------- |
| tiny document (half page)   | 0.033s        | 0.121s        |
| small document (5 pages)    | 0.141s        | 0.810s        |
| medium document (55 pages)  | 1.166s        | 10.524s       |
| large document (436 pages)  | 10.581s       | 108.095s      |


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