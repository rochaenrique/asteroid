package asteroid
import rl "vendor:raylib"

Rigid_Body :: struct {
	velocity, force: rl.Vector2,
	mass: f32,
}

make_rigid_body_full :: proc(velocity := rl.Vector2(0), force := rl.Vector2(0), mass: f32 = 1.0) -> Rigid_Body {
	return {
		force = force,
		velocity = velocity,
		mass = mass,
	}
}

make_rigid_body_position :: proc(v: rl.Vector2) -> Rigid_Body {
	return make_rigid_body_full(velocity=v)
}

make_rigid_body_rand :: proc(lower := rl.Vector2(0), upper := rl.Vector2(100)) -> Rigid_Body {
	v := 0.1 * rand_vec2(-upper, upper)
	return make_rigid_body_full(velocity=v)
}

make_rigid_body :: proc {
	make_rigid_body_full,
	make_rigid_body_position,
	make_rigid_body_rand,
}

resolve_rigid_body :: proc(rb: ^Rigid_Body, dt: f32) {
	rb.velocity += rb.force * dt / rb.mass
	rb.force = rl.Vector2(0)
}



