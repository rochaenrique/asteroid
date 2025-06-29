// insipred from https://github.com/karl-zylinski/odin-raylib-hot-reload-game-template/blob/main/source/main_hot_reload/main_hot_reload.odin

package editor

import "core:fmt"
import "core:os"
import "core:os/os2"
import "core:dynlib"
import "core:mem"
import "core:path/filepath"
import "core:log"

GAME_DLL_DIR :: "build"
GAME_DLL_PATH :: GAME_DLL_DIR + "/game" + DLL_EXT

Game :: struct {
	lib: dynlib.Library,
	lib_time: os.File_Time, 
	version: int,
	
	init, update, shutdown: proc(),
	running, force_reload, force_restart: proc() -> bool,
	hot_reloaded: proc(mem: rawptr),
	
	window_init, window_shutdown: proc(),

	memory: proc() -> rawptr,
	memory_size: proc() -> int,
}

copy_dll :: proc(to: string) -> bool {
	copy_err := os2.copy_file(to, GAME_DLL_PATH)
	if copy_err != nil {
		fmt.printfln("Failed to copy "+GAME_DLL_PATH+" to {0}: %v", to, copy_err)
	}
	return copy_err == nil
}

load_game :: proc(version: int) -> (game: Game, ok: bool) {
	time, time_err := os.last_write_time_by_name(GAME_DLL_PATH)
	if time_err != os.ERROR_NONE {
		fmt.printfln("Failed getting last write time of "+GAME_DLL_PATH+" error: {1}", time_err)
		return
	}

	game_dll_name := fmt.tprintf(GAME_DLL_DIR+"/game_{0}"+DLL_EXT, version)
	copy_dll(game_dll_name) or_return

	_, ok = dynlib.initialize_symbols(&game, game_dll_name, "game_", "lib")
	if !ok do fmt.printfln("Failed initializing symbols: {0}", dynlib.last_error())

	game.version = version
	game.lib_time = time
	ok = true
	return 
}

unload_game :: proc(game: ^Game) {
	if game.lib != nil && !dynlib.unload_library(game.lib) {
		fmt.printfln("Failed unloading lib: {0}", dynlib.last_error())
	}

	to_remove := fmt.tprintf(GAME_DLL_DIR+"/game_{0}"+DLL_EXT, game.version)
	if os.remove(to_remove) != nil {
		fmt.printfln("Failed to remove %s", to_remove)
	}
}

main :: proc() {
	exe_path := os.args[0]
	exe_dir := filepath.dir(string(exe_path))
	os.set_current_directory(exe_dir)

	default_allocator := context.allocator
	track: mem.Tracking_Allocator

	when ODIN_DEBUG {
		context.logger = log.create_console_logger()
		
		mem.tracking_allocator_init(&track, context.allocator)
		context.allocator = mem.tracking_allocator(&track)
		
		defer {
			if len(track.allocation_map) == 0 {
				fmt.println("No memory leaks!")
			} else {
				fmt.eprintf("%v allocations not freed\n", len(track.allocation_map))
				for _, entry in track.allocation_map {
					fmt.eprintfln("\t- %v bytes @ %v", entry.size, entry.location)
				}
				mem.tracking_allocator_destroy(&track)
			}
		}
	}

	game_version := 0
	game, game_ok := load_game(game_version)

	if !game_ok {
		fmt.println("Failed to load game!")
		return
	}

	game_version += 1
	game.window_init()
	game.init()

	old_games := make([dynamic]Game, default_allocator)

	fmt.println("Starting game version", game_version)
	
	for game.running() {
		game.update()
		
		force_restart := game.force_restart()
		game_dll_mod, game_dll_mod_err := os.last_write_time_by_name(GAME_DLL_PATH)
		
		reload := force_restart || game.force_reload() ||
			(game_dll_mod_err == os.ERROR_NONE && game.lib_time != game_dll_mod)

		if reload {
			fmt.printfln("Reloading game version %d", game_version)
			new_game, new_game_ok := load_game(game_version)
			if new_game_ok {
				fmt.println("New game Ok!")
				
				if !(force_restart || game.memory_size() != new_game.memory_size()) {
					append(&old_games, game)
					game_memory := game.memory()
					game = new_game
					game.hot_reloaded(game_memory)
					
				} else {
					game.shutdown()
					for &g in old_games do unload_game(&g)

					clear(&old_games)
					unload_game(&game)
					game = new_game
					game.init()
				}

				game_version += 1
			}
		}

		when ODIN_DEBUG { 
			if len(track.bad_free_array) > 0  {
				for &b in track.bad_free_array do log.errorf("Bad free at: %v", b.location)
			}
		}		
	}

	free_all(context.temp_allocator)
	game.shutdown()

	for &g in old_games do unload_game(&g)
	delete(old_games)

	game.window_shutdown()
	unload_game(&game)
}
