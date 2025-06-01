package asteroid
import rl "vendor:raylib"

Collision :: struct($A, $B: typeid) {
	a: ^A,
	b: ^B,
}

test_collision :: proc(a, b: ^$Entity) -> (coll: Collision(Entity, Entity), ok: bool) {
	ok = rl.Vector2Distance(a.body.position, b.body.position) < a.radius + b.radius
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
	for &e in ents do update_rigid_body(window_bounds, &e.body, dt)
}

solve_impulse :: proc(collisions: [dynamic]Collision($Entity, Entity)) {
	THRESHHOLD :: 1.0
	RESTITUTION :: 0.5
	
	for &c in collisions {
		// treating center as position
		// treating mass as proportional to radius
		abody : ^Rigid_Body = &c.a.body
		bbody : ^Rigid_Body = &c.b.body
		
		normal := rl.Vector2Normalize(abody.position - bbody.position)
		rvel := abody.velocity - bbody.velocity
		speed := rl.Vector2DotProduct(rvel, normal)

		if speed >= 0 do continue

		j := -(RESTITUTION + THRESHHOLD) * speed / (1/abody.mass + 1/bbody.mass)
		impulse := normal * j

		if rl.Vector2Length(impulse) > THRESHHOLD {
			abody.velocity += impulse / abody.mass
			bbody.velocity -= impulse / abody.mass
		}
		
		// for now no friction
	}
}
