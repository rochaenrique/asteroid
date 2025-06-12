package editor
import "core:c/libc"
import "core:os"

build_game :: proc() -> (out := false) {
	cmd : cstring = "odin build ." +
		"-extra-linker-flags:"+EXTRA_FLAGS +
		"-define:RAYLIB_SHARED=true" +
		"-build-mode:dll" +
		"-out:"+OUT_DIR+"/game_tmp"+DLL_EXT +
		"-strict-style -vet -debug"

	res := libc.system(cmd)
	(res != 0) or_return
	
	err := os.rename(OUT_DIR+"/game_tmp"+DLL_EXT, OUT_DIR+"/game"+DLL_EXT)
	(!err) or_return

	return true
}
