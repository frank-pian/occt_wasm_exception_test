from emscripten/emsdk:3.1.10

RUN apt-get update 

RUN apt-get install -y wget build-essential automake libtool autoconf cmake python3

############
# Freetype #
############

WORKDIR /opt/build
RUN wget https://download.savannah.gnu.org/releases/freetype/freetype-2.7.1.tar.gz
RUN tar -zxvf freetype-2.7.1.tar.gz >> installed_freetype271_files.txt
WORKDIR /opt/build/freetype-2.7.1
RUN sh autogen.sh
WORKDIR /opt/build/freetype-2.7.1/build
RUN cmake -G "Unix Makefiles" \
    -DCMAKE_TOOLCHAIN_FILE:FILEPATH="/emsdk/upstream/emscripten/cmake/Modules/Platform/Emscripten.cmake" \
    -DCMAKE_INSTALL_PREFIX=/opt/build/freetype-2.7.1-wasm ..
RUN make -j4 && make install

############
# opencascade #
############

WORKDIR /opt/build
RUN git clone --depth 1 https://git.dev.opencascade.org/repos/occt.git opencascade

RUN sed 's/-fexceptions/-fwasm-exceptions/' -i opencascade/adm/cmake/occt_defs_flags.cmake

WORKDIR /opt/build/opencascade/build

RUN emmake cmake \
  -DCMAKE_SIZEOF_VOID_P=8 \
  -DINSTALL_DIR=/opt/build/occt \
  -DBUILD_DOC_Overview:BOOL=FALSE \
  -DBUILD_MODULE_Draw=OFF \
  -DBUILD_LIBRARY_TYPE="Static" \
  -DCMAKE_BUILD_TYPE=release \
	-DUSE_FREETYPE:BOOL=ON \
	-D3RDPARTY_FREETYPE_DIR:PATH=/opt/build/freetype-2.7.1-wasm \
	-D3RDPARTY_FREETYPE_INCLUDE_DIR_freetype2=/opt/build/freetype-2.7.1-wasm/include \
	-D3RDPARTY_FREETYPE_INCLUDE_DIR_ft2build=/opt/build/freetype-2.7.1-wasm/include/freetype2 \
	-D3RDPARTY_FREETYPE_LIBRARY_DIR=/opt/build/freetype-2.7.1-wasm/lib \
  ..
  
RUN emmake make -j8
RUN emmake make install

###############
# Sample wasm #
###############
WORKDIR /opt/build/opencascade/samples/webgl/build
RUN emmake cmake \
  -Dfreetype_DIR=/opt/build/freetype-2.7.1-wasm/lib/cmake/freetype/ \
  -DOpenCASCADE_DIR=/opt/build/occt/lib/cmake/opencascade/ \
  -DCMAKE_INSTALL_PREFIX=/opt/build/webgl/ \
  ..
RUN emmake make
RUN emmake make install

WORKDIR /opt/build/webgl
RUN mv occt-webgl-sample occt-webgl-sample.js
RUN cp /opt/build/opencascade/data/occ/Ball.brep /opt/build/webgl

#################
# Simple servar #
#################

RUN apt-get -y install python3
EXPOSE 7000
CMD python3 -m http.server 7000

