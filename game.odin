package asteroid
import rl "vendor:raylib"
import "core:fmt"
import "core:math"

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
}

g: ^Game_Memory
update :: proc() {
	when ODIN_DEBUG {
        if wheel := rl.GetMouseWheelMove(); wheel != 0 {
            g.camera.offset = rl.GetMousePosition()
            g.camera.target = rl.GetScreenToWorld2D(rl.GetMousePosition(), g.camera)
            g.camera.zoom = rl.Clamp(math.exp(math.ln(g.camera.zoom)+0.2*wheel), 0.125, 64.0)
        }		
		
		if rl.IsMouseButtonDown(.LEFT) {
            g.camera.target += rl.GetMouseDelta() * -1.0/g.camera.zoom
		}
	}

	if rl.IsKeyPressed(.H) || rl.IsWindowResized() do set_window_bounds(&g.window_bounds)
	
	update_player(g.player, rl.GetFrameTime())
	update_entities(g.entities, rl.GetFrameTime(), &g.window_bounds)
}

draw :: proc() {
    rl.BeginDrawing()
    rl.ClearBackground(rl.BLACK)
	
	rl.BeginMode2D(g.camera)
	draw_entities(g.entities)
	when ODIN_DEBUG {
		rl.DrawRectangleLinesEx(window_bounds_rect(&g.window_bounds), 2, rl.RED)
	}
	rl.EndMode2D()

	when ODIN_DEBUG {
		rl.DrawFPS(10, 10)
		rl.DrawCircleV(rl.GetMousePosition(), 5, rl.GREEN)
	}
    rl.EndDrawing()
}

@(export)
game_init :: proc() {
	INIT_ASTEROIDS_N :: 10
	
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
		delete(e.shape.points)
	}
	delete(g.entities)
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
