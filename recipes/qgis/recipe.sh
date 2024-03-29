#!/bin/bash

# version of your package
VERSION_qgis=3.9

# dependencies of this recipe
DEPS_qgis=(libtasn1 gdal qca proj libspatialite libspatialindex expat gsl postgresql libzip qtkeychain)

# url of the package
URL_qgis=https://github.com/qgis/QGIS/archive/b884c0d5a1e081bd1de4924a084b89dc88ccdd2d.tar.gz

# md5 of the package
MD5_qgis=c349b03fd9beec1b0dcbbf886eb2c679

# default build path
BUILD_qgis=$BUILD_PATH/qgis/$(get_directory $URL_qgis)

# default recipe path
RECIPE_qgis=$RECIPES_PATH/qgis

# function called for preparing source code if needed
# (you can apply patch etc here.)
function prebuild_qgis() {
  cd $BUILD_qgis
  # check marker
  if [ -f .patched ]; then
    return
  fi

  module_dir=$(eval "echo \$O4iOS_qgis_DIR")
  if [ "$module_dir" ]
  then
    echo "\$O4iOS_qgis_DIR is not empty, manually patch your files if needed!"
  else
    try patch -p1 < $RECIPE_qgis/patches/std++11.patch
  fi

  touch .patched
}

function shouldbuild_qgis() {
 # If lib is newer than the sourcecode skip build
 if [ ${STAGE_PATH}/QGIS.app/Contents/MacOS/lib/qgis_quick.framework/qgis_quick -nt $BUILD_qgis/.patched ]; then
   DO_BUILD=0
 fi
}


# function called to build the source code
function build_qgis() {
  try mkdir -p $BUILD_PATH/qgis/build-$ARCH
  try cd $BUILD_PATH/qgis/build-$ARCH

  push_arm

  try ${CMAKECMD} \
    -DCMAKE_DISABLE_FIND_PACKAGE_HDF5=TRUE \
    -DWITH_DESKTOP=OFF \
    -DDISABLE_DEPRECATED=ON \
    -DWITH_QTWEBKIT=OFF \
    -FORCE_STATIC_LIBS=TRUE \
    -DQT_LRELEASE_EXECUTABLE=`which lrelease` \
    -DFLEX_EXECUTABLE=`which flex` \
    -DBISON_EXECUTABLE=`which bison` \
    -DGDAL_CONFIG=$STAGE_PATH/bin/gdal-config \
    -DGDAL_CONFIG_PREFER_FWTOOLS_PAT=/bin_safe \
    -DGDAL_CONFIG_PREFER_PATH=$STAGE_PATH/bin \
    -DGDAL_INCLUDE_DIR=$STAGE_PATH/include \
    -DGDAL_LIBRARY=$STAGE_PATH/lib/libgdal.a \
    -DGDAL_VERSION=2.4.0 \
    -DGEOS_CONFIG=$STAGE_PATH/bin/geos-config \
    -DGEOS_CONFIG_PREFER_PATH=$STAGE_PATH/bin \
    -DGEOS_INCLUDE_DIR=$STAGE_PATH/include \
    -DGEOS_LIBRARY=$STAGE_PATH/lib/libgeos_c.a \
    -DGEOS_LIB_NAME_WITH_PREFIX=-lgeos_c \
    -DGEOS_VERSION=3.7.2 \
    -DQCA_INCLUDE_DIR=$STAGE_PATH/include/QtCrypto \
    -DQCA_LIBRARY=$STAGE_PATH/lib/libqca-qt5.a \
    -DQCA_VERSION_STR=2.1.0 \
    -DPROJ_INCLUDE_DIR=$STAGE_PATH/include \
    -DPROJ_LIBRARY=$STAGE_PATH/lib/libproj.a \
    -DLIBTASN1_INCLUDE_DIR=$STAGE_PATH/include \
    -DLIBTASN1_LIBRARY=$STAGE_PATH/lib/libtasn1.a \
    -DLIBZIP_INCLUDE_DIR=$STAGE_PATH/include \
    -DLIBZIP_CONF_INCLUDE_DIR=$STAGE_PATH/include \
    -DLIBZIP_LIBRARY=$STAGE_PATH/lib/libzip.a \
    -DGSL_CONFIG=$STAGE_PATH/bin/gsl-config \
    -DGSL_CONFIG_PREFER_PATH=$STAGE_PATH/bin \
    -DGSL_EXE_LINKER_FLAGS=-Wl,-rpath, \
    -DGSL_INCLUDE_DIR=$STAGE_PATH/include/gsl \
    -DICONV_INCLUDE_DIR=$SYSROOT\
    -DICONV_LIBRARY=$SYSROOT/usr/lib/libiconv.tbd \
    -DSQLITE3_INCLUDE_DIR=$SYSROOT \
    -DSQLITE3_LIBRARY=$SYSROOT/usr/lib/libsqlite3.tbd \
    -DPOSTGRES_CONFIG= \
    -DPOSTGRES_CONFIG_PREFER_PATH= \
    -DPOSTGRES_INCLUDE_DIR=$STAGE_PATH/include \
    -DPOSTGRES_LIBRARY=$STAGE_PATH/lib/libpq.a \
    -DQTKEYCHAIN_INCLUDE_DIR=$STAGE_PATH/include/qt5keychain \
    -DQTKEYCHAIN_LIBRARY=$STAGE_PATH/lib/libqt5keychain.a \
    -DSPATIALINDEX_INCLUDE_DIR=$STAGE_PATH/include/spatialindex \
    -DSPATIALINDEX_LIBRARY=$STAGE_PATH/lib/libspatialindex.a \
    -DSPATIALITE_INCLUDE_DIR=$STAGE_PATH/include \
    -DSPATIALITE_LIBRARY=$STAGE_PATH/lib/libspatialite.a \
    -DPYTHON_EXECUTABLE=`which python3` \
    -DWITH_QT5SERIALPORT=OFF \
    -DWITH_BINDINGS=OFF \
    -DWITH_INTERNAL_SPATIALITE=OFF \
    -DWITH_ANALYSIS=OFF \
    -DWITH_GRASS=OFF \
    -DWITH_QTMOBILITY=OFF \
    -DWITH_QUICK=ON \
    -DCMAKE_INSTALL_PREFIX:PATH=$STAGE_PATH \
    -DENABLE_QT5=ON \
    -DENABLE_TESTS=OFF \
    -DEXPAT_INCLUDE_DIR=$STAGE_PATH/include \
    -DEXPAT_LIBRARY=$STAGE_PATH/lib/libexpat.a \
    -DWITH_INTERNAL_QWTPOLAR=OFF \
    -DWITH_QWTPOLAR=OFF \
    -DWITH_GUI=OFF \
    -DWITH_APIDOC=OFF \
    -DWITH_ASTYLE=OFF \
    -DCMAKE_DISABLE_FIND_PACKAGE_QtQmlTools=TRUE \
    -DIOS=TRUE \
    -DLIBTIFF_LIBRARY=$STAGE_PATH/lib/libtiff.a \
    -DLIBTIFFXX_LIBRARY=$STAGE_PATH/lib/libtiffxx.a \
    -DFREEXL_LIBRARY=$STAGE_PATH/lib/libfreexl.a \
    -DCHARSET_LIBRARY=$STAGE_PATH/lib/libcharset.a \
    -DGEOSCXX_LIBRARY=$STAGE_PATH/lib/libgeos.a \
    $BUILD_qgis

  try $MAKESMP install

  # Why it is not copied by CMake?
  cp $BUILD_PATH/qgis/build-$ARCH/src/core/qgis_core.h ${STAGE_PATH}/QGIS.app/Contents/Frameworks/qgis_core.framework/Headers/
  cp $BUILD_PATH/qgis/build-$ARCH/src/quickgui/qgis_quick.h ${STAGE_PATH}/QGIS.app/Contents/MacOS/lib/qgis_quick.framework/Headers/
  cp $BUILD_qgis/src/quickgui/plugin/qgsquickplugin.h ${STAGE_PATH}/QGIS.app/Contents/MacOS/lib/qgis_quick.framework/Headers/

  # https://github.com/qgis/QGIS/commit/90d40d5bb7408cc7afc91387305535f23aacbfb3
  mkdir -p ${STAGE_PATH}/QGIS.app/Contents/Frameworks/qgis_core.framework/Headers/nlohmann/
  cp $BUILD_qgis/external/nlohmann/json_fwd.hpp ${STAGE_PATH}/QGIS.app/Contents/Frameworks/qgis_core.framework/Headers/nlohmann/json_fwd.hpp

  # we need images too
  cp -R $BUILD_qgis/src/quickgui/images ${STAGE_PATH}/QGIS.app/Contents/Resources/images/QgsQuick

  pop_arm
}

# function called after all the compile have been done
function postbuild_qgis() {
  LIB_ARCHS=`lipo -archs ${STAGE_PATH}/QGIS.app/Contents/MacOS/lib/qgis_quick.framework/qgis_quick`
  if [[ $LIB_ARCHS != *"$ARCH"* ]]; then
    error "Library was not successfully build for ${ARCH}"
    exit 1;
  fi
}
