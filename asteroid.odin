package asteroid
import "core:math/rand"
import rl "vendor:raylib"

Asteroid :: struct {
	body: Rigid_Body,
	radius, rotation: f32,
	sides: i32,
}

// radius and rigid_body hold the same value for now

make_asteroids :: proc(num: int, window_bounds: ^[2]rl.Vector2) -> []Asteroid {
	asteroids := make([]Asteroid, num)
	for &ast in asteroids {
		radius := window_bounds[1].x * 0.025 + window_bounds[1].x *0.01 * rand.float32()
		ast = Asteroid {
			radius = radius,
			sides = 6 + rand.int31_max(4),
			body = make_rigid_body(rl.Vector2{0, 0}, window_bounds[1], radius),
		}
	}
	return asteroids
}

draw_asteroids :: proc(asteroids: []Asteroid) {
	for &a in asteroids {
		rl.DrawPoly(a.body.position, a.sides, a.radius, a.rotation, rl.GRAY)
	}
}

