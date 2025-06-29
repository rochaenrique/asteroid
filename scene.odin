package asteroid
import rl "vendor:raylib"
import "core:fmt"
import "core:strings"
import ease "core:math/ease"
import sa "core:container/small_array"
import "ui"

Scene_Type :: enum {
	Menu,  // main menu screen
	Play,  // regular playing screen
	Pause, // pause during play or maybe menu even? 
}

Scene_Table := [Scene_Type]Scene {
		.Menu  = { menu_init,  menu_destroy,  menu_update,  menu_draw  },
		.Play  = { play_init,  play_destroy,  play_update,  play_draw  },
		.Pause = { pause_init, pause_destroy, pause_update, pause_draw },
}

Scene :: struct {
	init, destroy: proc(),
	
	update: proc(f32),
	draw: proc(),
}

scene_current :: proc() -> (Scene, bool) {
	type, ok := sa.get_safe(g.scenes, sa.len(g.scenes) - 1)
	if ok do return Scene_Table[type], true
	return {}, false
}

scene_update :: proc(dt: f32) {
	curr, ok := scene_current()
	if ok do curr.update(dt)
}

scene_draw :: proc() {
	curr, ok := scene_current()
	if ok do curr.draw()
}

// always return after calling!!
scene_pop_handle :: proc() {
	type, ok := sa.pop_back_safe(&g.scenes)
	if ok do Scene_Table[type].destroy()
}

// always return after calling!!
scene_push_handle :: proc(scene: Scene_Type) {
	sa.push_back(&g.scenes, scene)
	Scene_Table[scene].init()
}

// ---------------------------------------------------------------------------
// Menu screen
// ---------------------------------------------------------------------------

menu_init :: proc() {
	ui.init()

	ui.root(
		ui.node({ alignment = .Center, scaling = .Relative, size = rl.Vector2{1, 0.3} }, rl.BLANK,
				ui.node({ alignment = .Top, scaling = .Fill }, rl.WHITE,
						ui.Text{ text = "Asteroid", spacing = 50 },
					   ),
				ui.node({ alignment = .Bottom, scaling = .Relative, size = rl.Vector2(0.1) }, rl.WHITE,
						ui.Text{ text = "Press <ENTER>", spacing = 10 },
					   ),
			   ),
	)
	
	ui.update()	
}

menu_update :: proc(dt: f32) {
 	if rl.IsKeyPressed(.ENTER) {
		scene_push_handle(.Play)
		return
	}

	if rl.IsWindowResized() {
		ui.update()
	}
}

menu_draw :: proc() {
	ui.draw()
}

menu_destroy :: proc() {
	ui.destroy()
}

// ---------------------------------------------------------------------------
// Play/level screen
// ---------------------------------------------------------------------------

play_init :: proc() {
	// make allocation cleaner and protected by global state
	g.entities = make([dynamic]Entity, 0, INIT_ASTEROIDS_N+1)
	g.alive_entities = make([dynamic]bool, 0, INIT_ASTEROIDS_N+1)
	g.entities_to_destroy = make([dynamic]EntityId)
	
	for i := 0; i < INIT_ASTEROIDS_N; i += 1 {
		game_create_entity()
	}

	center := get_window_center()
	g.player = {
		id = game_create_entity(center, 3, center.x * 0.03, false, 20.0, rl.BLUE),
		mode = .Park,
	}
	
	g.anims = ease.flux_init(f32)
}

play_update :: proc(dt: f32) {
	if rl.IsKeyPressed(.ESCAPE) {
		scene_push_handle(.Pause)
		return
	}
	
	if rl.IsKeyPressed(.F) {
		g.player.mode = .Drive if g.player.mode == .Sport else .Sport
	} else if rl.IsKeyPressed(.M) {
		g.player.mode = Player_Mode((int(g.player.mode) + 1) % len(Player_Mode))
	}

	update_player(&g.player, dt)
	update_entities(dt, &g.window_bounds)
	ease.flux_update(&g.anims, f64(dt))
}

play_draw :: proc() {
	rl.BeginMode2D(g.camera)
	for i in 0..<len(g.entities) {
		draw_entity(EntityId(i))
	}
	
	when ODIN_DEBUG {
		rl.DrawRectangleLinesEx(window_bounds_rect(&g.window_bounds), 2, rl.RED)
	}
	
	rl.EndMode2D()

	when ODIN_DEBUG { 
		str, ok := fmt.enum_value_to_string(g.player.mode)
		if ok {
			cstr := strings.clone_to_cstring(str, context.temp_allocator)
			rl.DrawText(cstr, 10, 30, 30, rl.BLUE)
		}
	}
}

play_destroy :: proc() {
	// make deallocation cleaner and protected by global state
	for _, &tween in &g.anims.values {
		tween.on_complete(&g.anims, tween.data)
	}
	ease.flux_destroy(g.anims)
	
	for alive, index in &g.alive_entities {
		if alive && index <= len(g.entities) do delete_entity(&g.entities[index])
	}
}

// ---------------------------------------------------------------------------
// Pause screen
// ---------------------------------------------------------------------------

pause_init :: proc() {
	ui.init()

	faded_red := rl.RED - rl.Color{0, 0, 0, 170}
	ui.root(
		ui.node({ alignment = .Center, scaling = .Relative, size = rl.Vector2{1, 0.2} }, rl.BLANK,
				ui.node({ alignment = .Top, scaling = .Relative, size = rl.Vector2(0.9) }, faded_red,
						ui.Text{ text = "Pause", spacing = 50 },
					   ),
				ui.node({ alignment = .Bottom, scaling = .Relative, size = rl.Vector2(0.2) }, faded_red,
						ui.Text{ text = "Press <ESC> to Return", spacing = 10 },
					   ),
			   ),
	)

	ui.update()
}

pause_update :: proc(dt: f32) {
	if rl.IsKeyPressed(.ESCAPE) {
		scene_pop_handle()
		return
	}

	if rl.IsWindowResized() {
		ui.update()
	}
}

pause_draw :: proc() {
	ui.draw()
}

pause_destroy :: proc() {
	ui.destroy()
}
