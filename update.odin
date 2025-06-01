package asteroid
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
	collisions := make([dynamic]Collision(Entity, Entity), context.temp_allocator)
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
		e.velocity += e.force * dt / e.radius
		e.position += e.velocity * dt
		e.position = clamp_vec(e.position, window_bounds[0], window_bounds[1])
		e.force = {0, 0}
	}
}

clamp_val :: proc(v: f32, minimum, maximum: f32) -> f32 {
	return minimum if v > maximum else maximum if v < minimum else v
}

clamp_vec :: proc(pos: rl.Vector2, minimum, maximum: rl.Vector2) -> rl.Vector2 {
	return {
		clamp_val(pos.x, minimum.x, maximum.x),
		clamp_val(pos.y, minimum.y, maximum.y),
	}
}

solve_impulse :: proc(collisions: [dynamic]Collision($Entity, Entity)) {
	THRESHHOLD :: 1.0
	
	for &c in collisions {
		// treating center as position
		// treating mass as proportional to radius
		normal := rl.Vector2Normalize(c.a.position - c.b.position)
		rvel := c.a.velocity - c.b.velocity
		speed := rl.Vector2DotProduct(rvel, normal)

		if speed >= 0 do continue

		j := -(1.0 + THRESHHOLD) *speed / (1/c.a.radius + 1/c.b.radius)
		impulse := normal * j

		if rl.Vector2Length(impulse) > THRESHHOLD {
			c.a.velocity += impulse / c.a.radius
			c.b.velocity -= impulse / c.b.radius
		}
		
		// for now no friction
	}
}
