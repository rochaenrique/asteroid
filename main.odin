package asteroid
import "core:fmt"
import "core:math/rand"
import rl "vendor:raylib"

rand_vec2 :: #force_inline proc(upper: rl.Vector2, lower := rl.Vector2{0, 0}) -> rl.Vector2 {
	return {
		rand.float32_range(lower.x, upper.x), 
		rand.float32_range(lower.x, upper.y)
	}
}

main :: proc() {
	INIT_WINDOW_SZ :: [2]i32{800, 600}
	INIT_ASTEROIDS_N :: 50
	
	// rl.SetConfigFlags({rl.ConfigFlag.WINDOW_RESIZABLE})
	rl.InitWindow(INIT_WINDOW_SZ.x, INIT_WINDOW_SZ.y, "Asteroid")
	rl.SetTargetFPS(60)
	
	window := rl.Vector2{
		cast(f32)rl.GetScreenWidth(),
		cast(f32)rl.GetScreenHeight()
	}
	
	asteroids := make_asteroids(INIT_ASTEROIDS_N, window)

    for !rl.WindowShouldClose() {
		window = {
			cast(f32)rl.GetScreenWidth(),
			cast(f32)rl.GetScreenHeight()
		}

		update_asteroids(window, asteroids, rl.GetFrameTime())
		
        rl.BeginDrawing()
        rl.ClearBackground(rl.BLACK)
		draw_asteroids(asteroids)
        rl.EndDrawing()
    }

    rl.CloseWindow()
}
