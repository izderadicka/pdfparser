#!/usr/bin/env python
from __future__ import print_function

import pdfparser.poppler as pdf
import argparse
import sys

p=argparse.ArgumentParser()
p.add_argument('document', help='Document file')
p.add_argument('--char-details', action='store_true', help='print character details')
p.add_argument('-f', '--first-page', type=int, help='first page')
p.add_argument('-l', '--last-page', type=int, help='first page')
p.add_argument('--phys-layout', action='store_true', help='Physical Layout - param for text analysis')
p.add_argument('--fixed-pitch', type=float, default=0.0, help='Fixed pitch - param for text analysis - app. max space size')
p.add_argument('-q', '--quiet', action='store_true', help='Silence all output from poppler')
args=p.parse_args()
d=pdf.Document(bytes(args.document), args.phys_layout, args.fixed_pitch, args.quiet)  # @UndefinedVariable
fp=args.first_page or 1
lp=args.last_page or d.no_of_pages
print('No of pages', d.no_of_pages)
for p in d:
    if p.page_no< fp or p.page_no>lp:
        continue
    print ('Page', p.page_no, 'size =', p.size)
    for f in p:
        print (' '*1,'Flow')
        for b in f:
            print (' '*2,'Block', 'bbox=', b.bbox.as_tuple())
            for l in b:
                print (' '*3, l.text.encode('UTF-8'), '(%0.2f, %0.2f, %0.2f, %0.2f)'% l.bbox.as_tuple())
                #assert l.char_fonts.comp_ratio < 1.0
                if args.char_details:
                    for i in range(len(l.text)):
                        print (l.text[i].encode('UTF-8'), '(%0.2f, %0.2f, %0.2f, %0.2f)'% l.char_bboxes[i].as_tuple(),\
                            l.char_fonts[i].name, l.char_fonts[i].size, l.char_fonts[i].color, )
                    print()