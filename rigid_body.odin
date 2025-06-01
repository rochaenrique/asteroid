package asteroid
import rl "vendor:raylib"

Rigid_Body :: struct {
	position, force, velocity: rl.Vector2,
	mass: f32,
}

make_rigid_body :: proc(lower := rl.Vector2{0, 0}, upper := rl.Vector2{0, 0}, init_mass : f32 = 1.0) -> Rigid_Body {
	return {
		position = rand_vec2(lower, upper),
		velocity = rand_vec2(-upper, upper) / 10,
		mass = init_mass,
	}
}

update_rigid_body :: proc(window_bounds: ^[2]rl.Vector2, body: ^Rigid_Body, dt: f32) {
		body.velocity += body.force * dt / body.mass
		body.position += body.velocity * dt
		body.position = clamp_vec(body.position, window_bounds[0], window_bounds[1])
		body.force = {0, 0}
}
