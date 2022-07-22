#!/bin/bash

pwd=`pwd`
lua=$pwd/ext/lua
lfs=$pwd/ext/luafilesystem
cjson=$pwd/ext/lua-cjson
log=$pwd/ext/lualogging

echo ""
echo "##############################################################################################"
echo "# Prepare"
echo "##############################################################################################"
echo ""

mkdir -p build/lua/include
cp -v src/*.lua build/
cp -v ext/luastatic/luastatic.lua build/

echo ""
echo "##############################################################################################"
echo "# Building Lua"
echo "##############################################################################################"
echo ""

make -C $lua all
cp -v $lua/*.a $pwd/build/lua
cp -v $lua/lua.h $lua/lauxlib.h $lua/luaconf.h $lua/lualib.h $pwd/build/lua/include

echo ""
echo "##############################################################################################"
echo "# Building luafilesystem"
echo "##############################################################################################"
echo ""

make -C $lfs LUA_VERSION=5.4 LUA_LIBDIR=$pwd/build/lua LUA_INC=-I$pwd/build/lua/include
cp -v $lfs/src/*.o $pwd/build

echo ""
echo "##############################################################################################"
echo "# Building lua-cjson"
echo "##############################################################################################"
echo ""

make -C $cjson LUA_VERSION=5.4 LUA_INCLUDE_DIR=$pwd/build/lua/include LUA_CMODULE_DIR=$pwd/build/lua
cp -v $cjson/*.o $pwd/build

echo ""
echo "##############################################################################################"
echo "# Copy lualogging"
echo "##############################################################################################"
echo ""

cp -v $log/src/logging.lua $pwd/build
mkdir -v $pwd/build/logging
cp -v $log/src/logging/rolling_file.lua $pwd/build/logging

echo ""
echo "##############################################################################################"
echo "# Building main file"
echo "##############################################################################################"
echo ""

cd $pwd/build
lua luastatic.lua \
  main.lua \
  fs.lua \
  vfio.lua \
  cpugov.lua \
  hugepages.lua \
  logging.lua \
  logging/rolling_file.lua \
  lfs.o \
  fpconv.o \
  strbuf.o \
  lua_cjson.o \
  lua/liblua.a \
  -I./lua/include \
  -o $pwd/qemu
cd $pwd

echo ""
echo "##############################################################################################"
echo "# Cleanup"
echo "##############################################################################################"
echo ""

make -C $lua clean
make -C $lfs clean
make -C $cjson clean
rm -Rv $pwd/build
