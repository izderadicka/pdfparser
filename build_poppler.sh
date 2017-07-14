#!/bin/sh
sudo apt-get update
sudo apt-get install -y libtool pkg-config gettext fontconfig libfontconfig1-dev autoconf libzip-dev libtiff5-dev libopenjpeg-dev
git clone --depth 1 https://anongit.freedesktop.org/git/poppler/poppler.git poppler_src 
cd poppler_src/
./autogen.sh
./configure --disable-poppler-qt4 --disable-poppler-qt5 --disable-poppler-cpp --disable-gtk-test --disable-splash-output --disable-utils
make
cp poppler/.libs/libpoppler.so.?? ../pdfparser/

