package asteroid
import "core:math/rand"
import rl "vendor:raylib"

Asteroid :: struct {
	body: Rigid_Body,
	radius, rotation: f32,
	sides: i32,
	shape: Shape,
}

// radius and rigid_body hold the same value for now

make_asteroids :: proc(num: int, window_bounds: ^[2]rl.Vector2) -> []Asteroid {
	asteroids := make([]Asteroid, num)
	for &ast in asteroids {
		radius := window_bounds[1].x * 0.025 + window_bounds[1].x *0.01 * rand.float32()
		ast = Asteroid {
			radius = radius,
			sides = 5 + rand.int31_max(4),
			body = make_rigid_body(rl.Vector2{0, 0}, window_bounds[1], radius),
		}
		ast.shape = shape_from_poly(ast.body.position, ast.sides, ast.radius, ast.rotation)
	}
	return asteroids
}

draw_asteroid_debug :: proc(a: ^Asteroid) {
	rl.DrawCircleLinesV(a.body.position, a.radius, rl.GREEN)
	rl.DrawSplineLinear(raw_data(a.shape.points), i32(len(a.shape.points)), 1.0, rl.GREEN)
}


draw_asteroids :: proc(asteroids: []Asteroid) {
	for &a in asteroids {
		rl.DrawPoly(a.body.position, a.sides, a.radius, a.rotation, rl.GRAY)
		when ODIN_DEBUG do draw_asteroid_debug(&a)
	}
}

update_asteroid_shape :: proc(a: ^Asteroid) {
	shape_from_poly(&a.shape, a.body.position, a.sides, a.radius, a.rotation)
}

