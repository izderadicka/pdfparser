#/bin/bash
echo 'PDF parsing with libpoppler'
time python -d dump_file.py test_docs/test1.pdf > /dev/null
echo 'PDF parsing with pdfminer'
time python tests/dump_file_pdfminer.py test_docs/test1.pdf > /dev/null
