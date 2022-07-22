PREFIX=$(shell pwd)
LUA_INCLUDE=$(PREFIX)/build/lua/include
LUASTATIC=$(PREFIX)/ext/luastatic/luastatic.lua

default: clean

prepare:
	@echo "--------------------------------------------------------"
	@echo "| Prepare"
	@echo "--------------------------------------------------------"
	mkdir -p $(PREFIX)/build/lua/include
	cp -v src/*.lua src/Makefile build/
	cp -v ext/luastatic/luastatic.lua build/

lua:
	@echo "--------------------------------------------------------"
	@echo "Building Lua"
	@echo "--------------------------------------------------------"
	cd $(PREFIX)/ext/lua && $(MAKE) all
	cp -v ext/lua/*.a $(PREFIX)/build/lua
	cp -v ext/lua/lua.h ext/lua/lauxlib.h ext/lua/luaconf.h ext/lua/lualib.h $(LUA_INCLUDE)

lfs:
	@echo "--------------------------------------------------------"
	@echo "| Building luafilesystem"
	@echo "--------------------------------------------------------"
	cd $(PREFIX)/ext/luafilesystem && $(MAKE) LUA_VERSION=5.4
	cp -v ext/luafilesystem/src/*.o $(PREFIX)/build

cjson:
	@echo "--------------------------------------------------------"
	@echo "| Building lua-cjson"
	@echo "--------------------------------------------------------"
	cd $(PREFIX)/ext/lua-cjson && $(MAKE)
	cp -v ext/lua-cjson/*.o $(PREFIX)/build

log:
	@echo "--------------------------------------------------------"
	@echo "| Copy lualogging"
	@echo "--------------------------------------------------------"
	mkdir -v $(PREFIX)/build/logging
	cd $(PREFIX)/ext/lualogging
	cp -v ext/lualogging/src/logging.lua $(PREFIX)/build
	cp -v ext/lualogging/src/logging/rolling_file.lua $(PREFIX)/build/logging

build: prepare lua lfs cjson log
	@echo "--------------------------------------------------------"
	@echo "| Building main file"
	@echo "--------------------------------------------------------"
	cd $(PREFIX)/build && $(MAKE) PREFIX=$(PREFIX)

clean: build
	@echo "--------------------------------------------------------"
	@echo "| Cleanup"
	@echo "--------------------------------------------------------"
	cd $(PREFIX)/ext/lua && $(MAKE) clean
	cd $(PREFIX)/ext/luafilesystem && $(MAKE) clean
	cd $(PREFIX)/ext/lua-cjson && $(MAKE) clean
	rm -Rv $(PREFIX)/build
