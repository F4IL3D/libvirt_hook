default: qemu

qemu:
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
		-o $(PREFIX)/qemu
