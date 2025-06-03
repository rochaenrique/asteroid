package asteroid
import rl "vendor:raylib"
import "core:fmt"

Game_Memory :: struct {
	window_bounds: [2]rl.Vector2,
	asteroids: []Asteroid,
	player: Player,
}

g: ^Game_Memory

set_window_bounds :: proc(bounds: ^[2]rl.Vector2) {
	width := f32(rl.GetScreenWidth())
	height := f32(rl.GetScreenHeight())
	bounds^ = {
		rl.Vector2{width * -0.1, height * -0.1}, 
		rl.Vector2{width * 1.1, height * 1.1}, 
	}
}

update :: proc() {
	if rl.IsWindowResized() do set_window_bounds(&g.window_bounds)
	update_player(&g.window_bounds, &g.player, rl.GetFrameTime())
	player_collisions(&g.player, g.asteroids) 
	update_collisions(g.asteroids)
	update_positions(&g.window_bounds, g.asteroids, rl.GetFrameTime())	
}

draw :: proc() {
    rl.BeginDrawing()
    	rl.ClearBackground(rl.BLACK)
		draw_asteroids(g.asteroids)
		draw_player(&g.player)
    rl.EndDrawing()	
}

@(export)
game_init :: proc() {
	INIT_ASTEROIDS_N :: 20

	g = new(Game_Memory)
	set_window_bounds(&g.window_bounds)
	g.asteroids = make_asteroids(INIT_ASTEROIDS_N, &g.window_bounds)
	g.player = make_player({ f32(rl.GetScreenWidth()), f32(rl.GetScreenHeight()) })

	fmt.printfln("Initialized game with %d asteroids", INIT_ASTEROIDS_N)
	fmt.println("Player Shape: ", g.player.shape)
}

@(export) 
game_update :: proc() {
	update()
	draw()
	free_all(context.temp_allocator)
}

@(export)
game_running :: proc() -> bool {
	return !rl.WindowShouldClose()
}

@(export)
game_shutdown :: proc() {
	for &a in g.asteroids {
		delete(a.shape.points)
	}
	delete(g.asteroids)
	free(g)
}

@(export)
game_force_reload :: proc() -> bool {
	return rl.IsKeyPressed(.R)
}

@(export)
game_force_restart :: proc() -> bool {
	return rl.IsKeyPressed(.G)
}

@(export)
game_hot_reloaded :: proc(mem: rawptr) {
	g = cast(^Game_Memory)mem
}

@(export)
game_window_init :: proc() {
	rl.SetConfigFlags({ .WINDOW_RESIZABLE })
	rl.InitWindow(800, 600, "Asteroid")
	rl.SetTargetFPS(60)
}

@(export)
game_window_shutdown :: proc() {
	rl.CloseWindow()
}

@(export)
game_memory :: proc() -> rawptr {
	return g
}

@(export)
game_memory_size :: proc() -> int {
	return size_of(Game_Memory)
}
