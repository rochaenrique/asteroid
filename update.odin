package asteroid
import "core:fmt"
import rl "vendor:raylib"

Collision :: struct($A, $B: typeid) {
	a: ^A,
	b: ^B,
}

test_collision :: proc(a, b: ^$Entity) -> (coll: Collision(Entity, Entity), ok: bool) {
	ok = rl.Vector2Distance(a.position, b.position) < a.radius + b.radius
	if ok do coll = Collision(Entity, Entity){a, b}
	return
}

update_collisions :: proc(ents: []$Entity) {
	collisions :[dynamic]Collision(Entity, Entity)
	for &a in ents {
		for &b in ents {
			if a == b do continue
			coll, ok := test_collision(&a, &b)
			if ok do append(&collisions, coll)
		}
	}

	solve_impulse(collisions)
}

update_positions :: proc(window_bounds: ^[2]rl.Vector2, ents: []$Entity, dt: f32) {
	for &e in ents {
		using e
		velocity += force * dt / radius
		position += velocity * dt
		position = clamp_vec(position, window_bounds[0], window_bounds[1])
		force = {0, 0}
	}
}

clamp_val :: proc(v: f32, minimum, maximum: f32) -> f32 {
	return minimum if v > maximum else maximum if v < minimum else v
}

clamp_vec :: proc(pos: rl.Vector2, minimum, maximum: rl.Vector2) -> rl.Vector2 {
	return {
		clamp_val(pos.x, minimum.x, maximum.x),
		clamp_val(pos.y, minimum.y, maximum.y)
	}
}

solve_impulse :: proc(collisions: [dynamic]Collision($Entity, Entity)) {
	THRESHHOLD :: 1.0
	
	for &col in collisions {
		// treating center as position
		// treating mass as proportional to radius
		using col
		normal := rl.Vector2Normalize(a.position - b.position)
		rvel := a.velocity - b.velocity
		speed := rl.Vector2DotProduct(rvel, normal)

		if speed >= 0 do continue

		restit := 1.0
		
		j := -(1.0 + THRESHHOLD) *speed / (1/a.radius + 1/b.radius)
		impulse := normal * j

		if rl.Vector2Length(impulse) > THRESHHOLD {
			a.velocity += impulse / a.radius
			b.velocity -= impulse / b.radius
		}
		
		// for now no friction
	}
}
