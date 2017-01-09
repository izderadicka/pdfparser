import pdfparser.poppler as pdf
import sys
import os.path
import psutil

def get_mem():
    p=psutil.Process()
    m=p.memory_info()
    return m.vms
test_doc=os.path.join(os.path.dirname(__file__), '../test_docs/test1.pdf')


start_mem=get_mem()
for counti in range(10000):
    imem=get_mem()
    
    d=pdf.Document(test_doc)
    
    pages=d.no_of_pages
    for p in d:
        pg_info= p.page_no, p.size
        for f in p:
            for b in f:
                bbox= b.bbox.as_tuple()
                for l in b:
                    line_info = l.text.encode('UTF-8'), l.bbox.as_tuple()
                    #assert l.char_fonts.comp_ratio < 1.0
                    for i in range(len(l.text)):
                        char_info = l.text[i].encode('UTF-8'), l.char_bboxes[i].as_tuple(), \
                            l.char_fonts[i].name, l.char_fonts[i].size, l.char_fonts[i].color,
    incr=(get_mem()-imem)
    if incr>0:
        print 'Iter no. %d'%counti,
        print 'Memory: %d' % get_mem(), 'Increase %d' % (get_mem()-imem)
    
print "Final memory increase %d" % ( get_mem() - start_mem)