package asteroid
import "core:math"
import "core:math/rand"
import rl "vendor:raylib"

Asteroid :: struct {
	center, force, velocity: rl.Vector2,
	radius, rotation: f32,
	sides: i32
}

make_asteroids :: proc(num: int, loc: rl.Vector2) -> []Asteroid {
	asteroids := make([]Asteroid, num)
	for &ast in asteroids {
		ast = Asteroid {
			center = rand_vec2(loc),
			force = {0, 0},
			velocity = rand_vec2(loc, -loc) / 10,
			radius = loc.x/50 + loc.x/80 * rand.float32(),
			rotation = 0.0,
			sides = 6 + rand.int31_max(4)
		}
	}
	return asteroids
}

update_asteroids :: proc(loc: rl.Vector2, asteroids: []Asteroid, dt: f32) {
	update_collisions(asteroids)
	update_positions(loc, asteroids, dt)
}

update_positions :: proc(loc: rl.Vector2, asteroids: []Asteroid, dt: f32) {
	for &ast in asteroids {
		using ast
		velocity += force * dt / radius
		center += velocity * dt
		
		if center.x > loc.x do center.x -= loc.x
		else if center.x < 0 do center.x += loc.x
		
		if center.y > loc.y do center.y -= loc.y
		else if center.y < 0 do center.y += loc.y
		
		force = {0, 0}
	}
}

draw_asteroids :: proc(asteroids: []Asteroid) {
	for &ast in asteroids {
		using ast
		rl.DrawPoly(center, sides, radius, rotation, rl.GRAY)
	}
}

