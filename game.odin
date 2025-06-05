package asteroid
import rl "vendor:raylib"
import "core:fmt"
import "core:math"
import ease "core:math/ease"

Window_Bounds :: struct {
	lower, upper: rl.Vector2,
}

WINDOW_BOUNDS_OFFSET : f32 : 0.1

set_window_bounds :: proc(bounds: ^Window_Bounds, offset := WINDOW_BOUNDS_OFFSET) {
	screen_world := rl.GetScreenToWorld2D(rl.Vector2{ f32(rl.GetScreenWidth()), f32(rl.GetScreenHeight()) }, g.camera)
	bounds^ = {
		lower = rl.GetScreenToWorld2D(rl.Vector2(0), g.camera) - screen_world * offset,
		upper = screen_world * (1.0 + offset),
	}
}

window_bounds_rect :: proc(bounds: ^Window_Bounds) -> rl.Rectangle {
	size := g.window_bounds.upper - g.window_bounds.lower
	return {
		x = g.window_bounds.lower.x,
		y = g.window_bounds.lower.y,
		width = size.x,
		height = size.y,
	}
}

window_bounds_center :: proc(bounds: ^Window_Bounds) -> rl.Vector2 {
	return (bounds.lower + bounds.upper) / 2
}

Game_Memory :: struct {
	window_bounds: Window_Bounds,
	entities: [dynamic]Entity,
	player: ^Entity,
	camera: rl.Camera2D,
	anims: ease.Flux_Map(f32),
}

g: ^Game_Memory

debug_camera_update :: proc(camera: ^rl.Camera2D) {
        if wheel := rl.GetMouseWheelMove(); wheel != 0 {
            camera.offset = rl.GetMousePosition()
            camera.target = rl.GetScreenToWorld2D(rl.GetMousePosition(), camera^)
            camera.zoom = rl.Clamp(math.exp(math.ln(camera.zoom)+0.2*wheel), 0.125, 64.0)
        }		
		
		if rl.IsMouseButtonDown(.LEFT) {
            camera.target += rl.GetMouseDelta() * -1.0/camera.zoom
		}
}

update :: proc() {
	when ODIN_DEBUG {
		debug_camera_update(&g.camera)
	}
	
	dt := rl.GetFrameTime()
	if rl.IsKeyPressed(.H) || rl.IsWindowResized() do set_window_bounds(&g.window_bounds)
	
	update_player(g.player, dt)
	update_entities(g.entities, dt, &g.window_bounds)
	ease.flux_update(&g.anims, f64(dt))
}

draw :: proc() {
    rl.BeginDrawing()
	rl.DrawFPS(10, 10)
    rl.ClearBackground(rl.BLACK)
	
	rl.BeginMode2D(g.camera)
	draw_entities(g.entities)
	when ODIN_DEBUG {
		rl.DrawRectangleLinesEx(window_bounds_rect(&g.window_bounds), 2, rl.RED)
	}
	
	rl.EndMode2D()
    rl.EndDrawing()
}

@(export)
game_init :: proc() {
	INIT_ASTEROIDS_N :: 1
	
	g = new(Game_Memory)
	
	screen := rl.Vector2{ f32(rl.GetScreenWidth()), f32(rl.GetScreenHeight()) }
	g.camera = rl.Camera2D{
		offset = screen / 2,
		target = screen / 2,
		rotation = 0,
		zoom = 1,
	}
	set_window_bounds(&g.window_bounds)
	g.entities = make([dynamic]Entity, 0, INIT_ASTEROIDS_N + 1)

	center := window_bounds_center(&g.window_bounds)
	append(&g.entities, make_entity(center, 3, center.x * 0.03, rl.BLUE))
	g.player = &g.entities[0]

	make_entities(&g.entities, INIT_ASTEROIDS_N, &g.window_bounds, rl.GRAY)

	// animations test
	g.anims = ease.flux_init(f32)
	fmt.printfln("Initialized game with %d entities", len(g.entities))
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
	for &e in &g.entities {
		delete_entity(&e)
	}
	delete(g.entities)
	
	for _, &tween in &g.anims.values {
		tween.on_complete(&g.anims, tween.data)
	}
	ease.flux_destroy(g.anims)
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
	rl.SetTargetFPS(30)
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
