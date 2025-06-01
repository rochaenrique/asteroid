package asteroid
import "core:math/rand"
import rl "vendor:raylib"

Asteroid :: struct {
	position, force, velocity: rl.Vector2,
	radius, rotation: f32,
	sides: i32,
}

rand_vec2 :: #force_inline proc(upper: rl.Vector2, lower := rl.Vector2{0, 0}) -> rl.Vector2 {
	return {
		rand.float32_range(lower.x, upper.x), 
		rand.float32_range(lower.x, upper.y),
	}
}

make_asteroids :: proc(num: int, window_bounds: ^[2]rl.Vector2) -> []Asteroid {
	asteroids := make([]Asteroid, num)
	for &ast in asteroids {
		ast = Asteroid {
			position = rand_vec2(window_bounds[1]),
			force = {0, 0},
			velocity = rand_vec2(window_bounds[1], -window_bounds[1]) / 10,
			radius = window_bounds[1].x/50 + window_bounds[1].x/80 * rand.float32(),
			rotation = 0.0,
			sides = 6 + rand.int31_max(4),
		}
	}
	return asteroids
}

draw_asteroids :: proc(asteroids: []Asteroid) {
	for &a in asteroids {
		rl.DrawPoly(a.position, a.sides, a.radius, a.rotation, rl.GRAY)
	}
}

