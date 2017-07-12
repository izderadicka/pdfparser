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