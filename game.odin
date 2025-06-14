package asteroid
import rl "vendor:raylib"
import "core:math"
import "core:fmt"
import ease "core:math/ease"

WINDOW_BOUNDS_OFFSET : f32 : 0.08
INIT_ASTEROIDS_N :: 1

Game_Memory :: struct {
	window_bounds: Window_Bounds,
	camera: rl.Camera2D,

	player: EntityId,
	entities: [dynamic]Entity,
	alive_entities: [dynamic]bool,
	entities_to_destroy: [dynamic]EntityId,
	
	anims: ease.Flux_Map(f32),
}

Window_Bounds :: struct {
	lower, upper: rl.Vector2,
}

g: ^Game_Memory

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

get_window_center :: proc() -> rl.Vector2 {
	return (g.window_bounds.lower + g.window_bounds.upper) / 2
}

game_get_entity :: proc(id: EntityId) -> ^Entity {
	if cast(int)id < len(g.entities) && g.alive_entities[id] do return &g.entities[id]
	return nil
}

game_entity_count :: proc() -> int {
	return len(g.entities)
}

game_add_entity :: proc(entity: Entity) -> EntityId {
	append(&g.entities, entity)
	append(&g.alive_entities, true)
	return EntityId(len(g.entities) - 1)
}

game_create_entity_poly :: proc(position: rl.Vector2, sides: int, radius: f32, static: bool, health := f32(1), color: rl.Color) -> EntityId {
	return game_add_entity(make_entity_poly(position, sides, radius, static, health, color))
}

game_create_entity_windowed :: proc() -> EntityId {
	return game_add_entity(make_entity(g.window_bounds.lower, g.window_bounds.upper))
}

game_create_entity :: proc{
	game_create_entity_windowed,
	game_create_entity_poly,
}

game_destroy_entity :: proc(entity: EntityId) {
	append(&g.entities_to_destroy, entity)
}

destroy_entities :: proc() {
}

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
	
	if rl.IsKeyPressed(.H) || rl.IsWindowResized() {
		set_window_bounds(&g.window_bounds)
	}

	update_player(g.player, dt)
	update_entities(dt, &g.window_bounds)
	ease.flux_update(&g.anims, f64(dt))
}

draw :: proc() {
    rl.BeginDrawing()
	rl.DrawFPS(10, 10)
    rl.ClearBackground(rl.BLACK)
	
	rl.BeginMode2D(g.camera)
	for i in 0..<len(g.entities) {
		draw_entity(EntityId(i))
	}
	
	when ODIN_DEBUG {
		rl.DrawRectangleLinesEx(window_bounds_rect(&g.window_bounds), 2, rl.RED)
	}
	
	rl.EndMode2D()
    rl.EndDrawing()
}

@(export)
game_init :: proc() {
	g = new(Game_Memory)
	
	screen := rl.Vector2{ f32(rl.GetScreenWidth()), f32(rl.GetScreenHeight()) }
	g.camera = rl.Camera2D{
		offset = screen / 2,
		target = screen / 2,
		rotation = 0,
		zoom = 1,
	}
	set_window_bounds(&g.window_bounds)

	g.entities = make([dynamic]Entity, 0, INIT_ASTEROIDS_N+1)
	g.alive_entities = make([dynamic]bool, 0, INIT_ASTEROIDS_N+1)
	g.entities_to_destroy = make([dynamic]EntityId)
	for i := 0; i < INIT_ASTEROIDS_N; i += 1 {
		game_create_entity()
	}
	
	center := get_window_center()
	g.player = game_create_entity(center, 3, center.x * 0.03, false, 20.0, rl.BLUE)

	g.anims = ease.flux_init(f32)
}

@(export) 
game_update :: proc() {
	update()
	draw()
	if len(g.entities_to_destroy) != 0 {
		fmt.printfln("Destroying %d entities", len(g.entities_to_destroy))
		for &index in g.entities_to_destroy {
			e := game_get_entity(index)
			if e != nil {
				delete_entity(&g.entities[index])
				g.alive_entities[index] = false
			}
		}
		clear(&g.entities_to_destroy)
	}
	free_all(context.temp_allocator)
}

@(export)
game_running :: proc() -> bool {
	return !rl.WindowShouldClose()
}

@(export)
game_shutdown :: proc() {
	for _, &tween in &g.anims.values {
		tween.on_complete(&g.anims, tween.data)
	}
	ease.flux_destroy(g.anims)
	
	for alive, index in &g.alive_entities {
		if alive && index <= len(g.entities) do delete_entity(&g.entities[index])
	}
	
	delete(g.entities)
	delete(g.alive_entities)
	delete(g.entities_to_destroy)

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
