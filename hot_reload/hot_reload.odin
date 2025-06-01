package hot_reload

import "core:os"
import "core:fmt"
import "core:path/filepath"
import "core:c/libc"
import s "core:strings"

OUT_DIR :: "build"

when ODIN_OS == .Darwin {
	DLL_EXT :: ".dylib"
	EXTRA_FLAGS :: "\"-Wl,-rpath "+ODIN_ROOT+"vendor/raylib/macos\""
} else {
	DLL_EXT :: ".so"
	// EXTRA_FLAGS :: "-Wl,-rpath \$ORIGIN/linux"
}

cmd_append :: proc(cmd: ^s.Builder, args: ..string) {
	for &a in args {
		s.write_string(cmd, a)
		s.write_byte(cmd, ' ')
	}
}

cmd_run :: proc(cmd: ^s.Builder) -> i32 {
	fmt.println("[CMD]", s.to_string(cmd^))
	defer s.builder_destroy(cmd)
	return libc.system(s.to_cstring(cmd))
}

compile_game :: proc(tmp_name: string) -> i32 {
	cmd := s.builder_make()
	
	cmd_append(&cmd, "odin build .")
	cmd_append(&cmd, "-extra-linker-flags:"+EXTRA_FLAGS)
	cmd_append(&cmd, "-define:RAYLIB_SHARED=true")
	cmd_append(&cmd, "-build-mode:dll")
	cmd_append(&cmd, fmt.tprintf("-out:%s", tmp_name))
	cmd_append(&cmd, "-strict-style", "-vet", "-debug")

	return cmd_run(&cmd)
}

compile_editor :: proc(run := false) -> i32 {
	cmd := s.builder_make()
	cmd_append(&cmd, fmt.tprintf("odin %s editor", "run" if run else "build"))
	cmd_append(&cmd, "-strict-style", "-vet", "-debug")
	
	return cmd_run(&cmd)
}

is_editor_running :: proc() -> bool {
	cmd := s.clone_to_cstring(fmt.tprintf("pgrep -f %s > /dev/null", os.args[0]))
	return libc.system(cmd) == 0
}

main :: proc() {
	os.set_current_directory(filepath.dir(string(os.args[0])))
	if !os.exists(OUT_DIR) do os.make_directory(OUT_DIR)
	
	fmt.println("Building Game")
	
	tmp_name := OUT_DIR+"/game_tmp"+DLL_EXT
	if compile_game(tmp_name) != 0 {
		fmt.println("Failed to compile game!")
		os.exit(1)
	}
	
	solid_name := OUT_DIR+"/game"+DLL_EXT
	fmt.printfln("Renaming %s to %s", tmp_name, solid_name)
	
	if !os.rename(tmp_name, solid_name) {
		fmt.printfln("Error while renaming:")
		os.exit(1)
	}

	if is_editor_running() {
		fmt.println("Editor is running")
	} else {
		fmt.println("Building editor")
		compile_editor()
	}
}
