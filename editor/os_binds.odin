package editor

when ODIN_OS == .Darwin {
	DLL_EXT :: ".dylib"
	LIB_PATH :: "macos"
	EXTRA_FLAGS :: "-Wl,-rpath "+ODIN_ROOT+"+vendor/raylib/"+LIB_PATH
} else {
	DLL_EXT :: ".so"
	EXTRA_FLAGS :: "-Wl,-rpath "+ODIN_ROOT+"/linux"
	
}


OUT_DIR :: "build"

