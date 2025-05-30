package asteroid
import "core:fmt"
import "core:c"
import "core:math/rand"
import rl "vendor:raylib"

set_window_bounds :: proc(bounds: ^[2]rl.Vector2) {
	width := cast(f32)rl.GetScreenWidth()
	height := cast(f32)rl.GetScreenHeight()
	bounds^ = {
		rl.Vector2{width * -0.1, height * -0.1}, 
		rl.Vector2{width * 1.1, height * 1.1}, 
	}
}

main :: proc() {
	INIT_WINDOW_SZ :: [2]i32{800, 600}
	INIT_ASTEROIDS_N :: 50
	
	// rl.SetConfigFlags({rl.ConfigFlag.WINDOW_RESIZABLE})
	rl.InitWindow(INIT_WINDOW_SZ.x, INIT_WINDOW_SZ.y, "Asteroid")
	rl.SetTargetFPS(60)
	
	window_bounds : [2]rl.Vector2;
	set_window_bounds(&window_bounds)

	asteroids := make_asteroids(INIT_ASTEROIDS_N, &window_bounds)

    for !rl.WindowShouldClose() {
		if rl.IsWindowResized() do set_window_bounds(&window_bounds)

		update_collisions(asteroids)
		update_positions(&window_bounds, asteroids, rl.GetFrameTime())
		
        rl.BeginDrawing()
        rl.ClearBackground(rl.BLACK)
		draw_asteroids(asteroids)
        rl.EndDrawing()
    }

    rl.CloseWindow()
}
