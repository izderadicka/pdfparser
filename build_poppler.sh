#!/bin/sh
sudo -E apt-get update
sudo -E apt-get install -y libtool pkg-config gettext fontconfig libfontconfig1-dev cmake libzip-dev 
git clone --branch poppler-0.62.0 --depth 1 https://anongit.freedesktop.org/git/poppler/poppler.git poppler_src 
cd poppler_src/
cmake -DENABLE_SPLASH=OFF -DENABLE_UTILS=OFF -DENABLE_LIBOPENJPEG=none .
make
cp libpoppler.so.?? ../pdfparser/
cp cpp/libpoppler-cpp.so.? ../pdfparser
cd ..

