package asteroid
import rl "vendor:raylib"
import "core:math/rand"

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

make_rigid_body_velocity :: proc(v: rl.Vector2) -> Rigid_Body {
	return make_rigid_body_full(velocity=v)
}

make_rigid_body_rand :: proc(lower := rl.Vector2(0), upper := rl.Vector2(100)) -> Rigid_Body {
	velocity := 0.15 * rand_vec2(lower, upper) 
	mass := (upper.x - lower.x) * 0.03 * (1.0 + rand.float32())
	return make_rigid_body_full(velocity=velocity, mass=mass)
}

make_rigid_body :: proc {
	make_rigid_body_velocity,
	make_rigid_body_rand,
	make_rigid_body_full,
}

resolve_rigid_body :: proc(rb: ^Rigid_Body, dt: f32) {
	rb.velocity += rb.force * dt / rb.mass
	rb.force = rl.Vector2(0)
}

