'''
Created on Feb 21, 2016

@author: ivan
'''


import pdfparser.poppler as pdf
import sys

d=pdf.Document(sys.argv[1])

print 'No of pages', d.no_of_pages
for p in d:
    print 'Page', p.page_no, 'size =', p.size
    for f in p:
        print ' '*1,'Flow'
        for b in f:
            print ' '*2,'Block', 'bbox=', b.bbox
            for l in b:
                print ' '*3, l.text.encode('UTF-8'), '(%0.2f, %0.2f, %0.2f, %0.2f)'% l.bbox
                #assert l.char_fonts.comp_ratio < 1.0
                for i in range(len(l.text)):
                    print l.text[i].encode('UTF-8'), '(%0.2f, %0.2f, %0.2f, %0.2f)'% l.char_bboxes[i].as_tuple(),\
                        l.char_fonts[i].name, l.char_fonts[i].size, l.char_fonts[i].color,
                print