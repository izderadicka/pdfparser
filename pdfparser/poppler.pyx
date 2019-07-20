from libcpp cimport bool
from libcpp.string cimport string
from cpython cimport bool as PyBool
from cpython.object cimport Py_EQ, Py_NE

ctypedef bool GBool
DEF PRECISION=1e-6

cdef extern from "cpp/poppler-version.h" namespace "poppler":
    cdef string version_string()

def poppler_version():
    return version_string()

cdef extern from "GlobalParams.h":
    GlobalParams *globalParams
    cdef cppclass GlobalParams:
        void setErrQuiet(bool)
        bool getErrQuiet()
 # we need to init globalParams - just once during program run
globalParams = new GlobalParams()

IF USE_CSTRING:
    cdef extern from "goo/GooString.h":
        cdef cppclass GooString:
            GooString(const char *sA)
            int getLength()
            const char *c_str()
            char getChar(int i)
ELSE:
    cdef extern from "goo/GooString.h":
        cdef cppclass GooString:
            GooString(const char *sA)
            int getLength()
            const char *getCString()
            char getChar(int i)
cdef extern from "OutputDev.h":
    cdef cppclass OutputDev:
        pass
    
cdef extern from 'Annot.h':
    cdef cppclass Annot:
        pass
        
cdef extern from "PDFDoc.h":
    cdef cppclass PDFDoc:
        int getNumPages()
        void displayPage(OutputDev *out, int page,
           double hDPI, double vDPI, int rotate,
           GBool useMediaBox, GBool crop, GBool printing,
           GBool (*abortCheckCbk)(void *data) = NULL,
           void *abortCheckCbkData = NULL,
            GBool (*annotDisplayDecideCbk)(Annot *annot, void *user_data) = NULL,
            void *annotDisplayDecideCbkData = NULL, GBool copyXRef = False)
        double getPageMediaWidth(int page)
        double getPageMediaHeight(int page)
        
cdef extern from "PDFDocFactory.h":
    cdef cppclass PDFDocFactory:
        PDFDocFactory()
        PDFDoc *createPDFDoc(const GooString &uri, GooString *ownerPassword = NULL,
                             GooString *userPassword = NULL, void *guiDataA = NULL)
        
cdef extern from "TextOutputDev.h":
    cdef cppclass TextOutputDev:
        TextOutputDev(char *fileName, GBool physLayoutA,
        double fixedPitchA, GBool rawOrderA, GBool append)
        TextPage *takeText()
        
    cdef cppclass TextPage:
        void incRefCnt()
        void decRefCnt()
        TextFlow *getFlows()
        
    cdef cppclass TextFlow:
        TextFlow *getNext()
        TextBlock *getBlocks()
        
    cdef cppclass TextBlock:
        TextBlock *getNext()
        TextLine *getLines()
        void getBBox(double *xMinA, double *yMinA, double *xMaxA, double *yMaxA)
        
    cdef cppclass TextLine:
        TextWord *getWords()
        TextLine *getNext()
        
    cdef cppclass TextWord:
        TextWord *getNext()
        int getLength()
        GooString *getText()
        void getBBox(double *xMinA, double *yMinA, double *xMaxA, double *yMaxA)
        void getCharBBox(int charIdx, double *xMinA, double *yMinA,
           double *xMaxA, double *yMaxA)
        GBool hasSpaceAfter  ()
        TextFontInfo *getFontInfo(int idx)
        GooString *getFontName(int idx)
        double getFontSize()
        void getColor(double *r, double *g, double *b)
        
    cdef cppclass TextFontInfo:
        GooString *getFontName() 
        double getAscent();
        double getDescent();

        GBool isFixedWidth() 
        GBool isSerif() 
        GBool isSymbolic() 
        GBool isItalic() 
        GBool isBold() 
         
        
       
cdef double RESOLUTION=72.0
        

cdef class Document:
    cdef: 
        PDFDoc *_doc
        int _pg
        PyBool phys_layout
        double fixed_pitch
    def __cinit__(self, char *fname, PyBool phys_layout=False, double fixed_pitch=0, PyBool quiet=False):
        self._doc=PDFDocFactory().createPDFDoc(GooString(fname))
        self._pg=0
        self.phys_layout=phys_layout
        self.fixed_pitch=fixed_pitch

        if quiet:
            globalParams.setErrQuiet(True)
        
    def __dealloc__(self):
        if self._doc != NULL:
            del self._doc
            
    property no_of_pages:
        def __get__(self):
            return self._doc.getNumPages()  
        
    cdef void render_page(self, int page_no, OutputDev *dev):
        self._doc.displayPage(dev, page_no, RESOLUTION, RESOLUTION, 0, True, False, False)
     
    cdef object get_page_size(self, page_no):
            cdef double w,h
            w=self._doc.getPageMediaWidth(page_no)
            h= self._doc.getPageMediaHeight(page_no)
            return (w,h)
            
    def __iter__(self):
        return self
    
    def get_page(self, int pg):
        return Page(pg, self)
    
    def __next__(self):
        if self._pg >= self.no_of_pages:
            raise StopIteration()
        self._pg+=1
        return self.get_page(self._pg)
        
   
        
cdef class Page:
    cdef:
        int page_no
        TextPage *page
        Document doc
        TextFlow *curr_flow
        
    def __cinit__(self, int page_no, Document doc):
        cdef TextOutputDev *dev
        self.page_no=page_no
        dev = new TextOutputDev(NULL, doc.phys_layout, doc.fixed_pitch, False, False);
        doc.render_page(page_no, <OutputDev*> dev)
        self.page= dev.takeText()
        del dev
        self.curr_flow = self.page.getFlows()
        self.doc=doc
    
    def __dealloc__(self):
        if self.page != NULL:
            self.page.decRefCnt()
            
    def __iter__(self):
        return self
    
    def __next__(self):
        cdef Flow f
        if not self.curr_flow:
            raise StopIteration()
        f=Flow(self)
        self.curr_flow=self.curr_flow.getNext()
        return f
            
    property page_no:
        def __get__(self):
            return self.page_no
        
    property size:
        """Size of page as (width, height)"""
        def __get__(self):
            return self.doc.get_page_size(self.page_no)
        
cdef class Flow:
    cdef: 
        TextFlow *flow
        TextBlock *curr_block
    
    def __cinit__(self, Page pg):
        self.flow=pg.curr_flow
        self.curr_block=self.flow.getBlocks()
    
    def __iter__(self):
        return self
    
    def __next__(self):
        cdef Block b
        if not self.curr_block:
            raise StopIteration()
        b=Block(self)
        self.curr_block=self.curr_block.getNext()
        return b
    
cdef class Block:
    cdef:
        TextBlock *block
        TextLine *curr_line
        
    def __cinit__(self, Flow flow):
        self.block= flow.curr_block
        self.curr_line=self.block.getLines()
        
#TODO - do we need to delete blocks, lines ... or are they destroyed with page?        
#     def __dealloc__(self):
#         if self.block != NULL:
#             del self.block
        
    def __iter__(self):
        return self
    
    def __next__(self):
        cdef Line l
        if not self.curr_line:
            raise StopIteration()
        l=Line(self)
        self.curr_line=self.curr_line.getNext()
        return l
        
    property bbox:
        def __get__(self):
            cdef double x1,y1,x2,y2
            self.block.getBBox(&x1, &y1, &x2, &y2)
            return  BBox(x1,y1,x2,y2)
        
cdef class BBox:
    cdef double x1, y1, x2, y2
    
    def __cinit__(self, double x1, double y1, double x2, double y2 ):
        self.x1=x1
        self.x2=x2
        self.y1=y1
        self.y2=y2
        
    def as_tuple(self):
        return self.x1,self.y1, self.x2, self.y2
    
    def __getitem__(self, i):
        if i==0:
            return self.x1
        elif i==1:
            return self.y1
        elif i==2:
            return self.x2
        elif i==3:
            return self.y2
        raise IndexError()
        
    property x1:
        def __get__(self):
            return self.x1
        def __set__(self, double val):
            self.x1=val
            
    property x2:
        def __get__(self):
            return self.x2
        def __set__(self, double val):
            self.x2=val
            
    property y1:
        def __get__(self):
            return self.y1
        def __set__(self, double val):
            self.y1=val
            
    property y2:
        def __get__(self):
            return self.y2
        def __set__(self, double val):
            self.y2=val

cdef class Color:
    cdef:
        double r,b,g
    
    def __cinit__(self, double r, double g, double b):
        self.r = r
        self.g = g
        self.b = b
        
        
    def as_tuple(self):
        return self.r,self.g, self.b
        
    property r:
        def __get__(self):
            return self.r
        
            
    property g:
        def __get__(self):
            return self.g
        
            
    property b:
        def __get__(self):
            return self.b
        
            
    def __str__(self):
        return 'r:%0.2f g:%0.2f, b:%0.2f' % self.as_tuple()
    
    def __richcmp__(x, y, op):
        if isinstance(x, Color) and isinstance(y, Color) and (op == Py_EQ or op == Py_NE):
            eq = abs(x.r - y.r) < PRECISION and \
                 abs(x.g -y.g) < PRECISION and \
                 abs(x.b -y.b) < PRECISION 
            return eq if op == Py_EQ else not eq
        return NotImplemented
        
    
cdef class FontInfo:
    cdef:
        unicode name
        double size
        Color color
        
    def __cinit__(self, unicode name, double size, Color color):
        nparts=name.split('+',1)
        self.name=nparts[-1]
        self.size=size
        self.color=color
        
    property name:
        def __get__(self):
            return self.name
        def __set__(self, unicode val):
            self.name=val
            
    property size:
        def __get__(self):
            return self.size
        def __set__(self, double val):
            self.size=val
            
    property color:
        def __get__(self):
            return self.color
        def __set__(self, Color val):
            self.color=val
            
    def __richcmp__(x, y, op):
        if isinstance(x, FontInfo) and isinstance(y, FontInfo) and (op == Py_EQ or op == Py_NE):
            eq = x.name == y.name and \
                 abs(x.size -y.size) < PRECISION and \
                 x.color == y.color
            return eq if op == Py_EQ else not eq
        return NotImplemented



cdef class CompactListIterator:
    cdef:
        list index
        list items
        int pos
        
    def __cinit__(self, list index, list items):
        self.pos=0
        self.index=index
        self.items=items
        
    def __next__(self):
        if self.pos >= len(self.index):
            raise StopIteration()
        i= self.items[self.index[self.pos]]
        self.pos+=1
        return i
        
            
cdef class CompactList:
    cdef:
        list index
        list items
        
    def __init__(self):
        self.index=[]
        self.items=[]
        
        
    def append(self, v):
        cdef long last
        last=len(self.items)-1
        if last>=0 and self.items[last] == v:
            self.index.append(last)
        else:
            self.items.append(v)
            self.index.append(last+1)
            
    def __getitem__(self, idx):
        return self.items[self.index[idx]]
        
    def __len__(self):
        return len(self.index)
    
    def __iter__(self):
        return CompactListIterator(self.index, self.items)
    
    property comp_ratio:
        def __get__(self):
            return float(len(self.items)) / len(self.index)
    

        
cdef class Line:
    cdef:
        TextLine *line
        double x1, y1, x2, y2
        unicode _text
        list _bboxes
        CompactList _fonts
        
        
    def __cinit__(self, Block block):
        self.line = block.curr_line
        
    def __init__(self, Block block):
        self._text=u'' # text bytes
        self.x1 = 0
        self.y1 = 0
        self.x2 = 0
        self.y2 = 0
        self._bboxes=[]
        self._fonts=CompactList()
        self._get_text()
        assert len(self._text) == len(self._bboxes)
           
    def _get_text(self):
        cdef: 
            TextWord *w
            GooString *s
            double bx1,bx2, by1, by2
            list words = []
            int offset = 0, i, wlen
            BBox last_bbox 
            FontInfo last_font
            double r,g,b
        
        w=self.line.getWords()
        while w:
            wlen=w.getLength()
            assert wlen>0
            # gets bounding boxes for all characters
            # and font info
            for i in range(wlen):
                w.getCharBBox(i, &bx1, &by1, &bx2, &by2 )
                last_bbox=BBox(bx1,by1,bx2,by2)
                # if previous word is space update it's right end
                if i == 0 and words and words[-1] == u' ':
                    self._bboxes[-1].x2=last_bbox.x1
                    
                self._bboxes.append(last_bbox)
                w.getColor(&r, &g, &b)
                font_name=w.getFontName(i)
                IF USE_CSTRING:
                    font_name_cstr = font_name.c_str()
                ELSE:
                    font_name_cstr = font_name.getCString()
                last_font=FontInfo(font_name_cstr.decode('UTF-8', 'replace') if <unsigned long>font_name != 0 else u"unknown", # In rare cases font name is not UTF-8 or font name is NULL
                                   w.getFontSize(),
                                   Color(r,g,b)
                                   )
                self._fonts.append(last_font)
            #and then text as UTF-8 bytes
            s=w.getText()
            #print s.getCString(), w.getLength(), len(s.getCString())
            IF USE_CSTRING:
                s_cstr = s.c_str()
            ELSE:
                s_cstr = s.getCString()
            words.append(s_cstr.decode('UTF-8')) # decoded to python unicode string
            del s
            # must have same ammount of bboxes and characters in word
            assert len(words[-1]) == wlen
            #calculate line bbox
            w.getBBox(&bx1, &by1, &bx2, &by2)
            if bx1 < self.x1 or self.x1 == 0:
                self.x1=bx1
            if by1 < self.y1 or self.y1 == 0:
                self.y1= by1
            if bx2 > self.x2:
                self.x2=bx2
            if by2 > self.y2:
                self.y2=by2
            # add space after word if necessary    
            if w.hasSpaceAfter():
                words.append(u' ')
                self._bboxes.append(BBox(last_bbox.x2, last_bbox.y1, last_bbox.x2, last_bbox.y2))
                self._fonts.append(last_font)
            w=w.getNext()
        self._text= u''.join(words)
        
    property bbox:
        def __get__(self):
            return BBox(self.x1,self.y1,self.x2,self.y2)
        
    property text:
        def __get__(self):
            return self._text
        
    property char_bboxes:
        def __get__(self):
            return self._bboxes
        
    property char_fonts:
        def __get__(self):
            return self._fonts
            
        
    
        
    
    
    
