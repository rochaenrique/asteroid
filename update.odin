package asteroid
import rl "vendor:raylib"

Collision :: struct($A, $B: typeid) {
	a: ^A,
	b: ^B,
}

collided_generic :: proc(a: ^$A, b: ^$B) -> bool {
	return rl.CheckCollisionCircles(a.body.position, a.radius, a.body.position, a.radius)
}

collided_player_asteroid :: proc(p: ^Player, b: ^Asteroid) -> bool {
	i := 0
	for i < len(p.shape.points) {
		if rl.CheckCollisionPointCircle(p.shape.points[i], b.body.position, b.radius) do break
	}
	return i < len(p.shape.points)
}

collided :: proc {
	collided_generic,
	collided_player_asteroid,
}

test_collision :: proc(a: ^$A, b: ^$B) -> (coll: Collision(A, B), ok: bool) {
	ok = collided(a, b)
	if ok do coll = Collision(A, B){a, b}
	return
}

update_collisions :: proc(ents: []$Entity) {
	collisions := make([dynamic]Collision(Entity, Entity), context.temp_allocator)
	for &a in ents {
		for &b in ents {
			(&a != &b) or_continue
			if coll, ok := test_collision(&a, &b); ok do append(&collisions, coll)
		}
	}

	solve_impulse(collisions)
}

update_positions :: proc(window_bounds: ^[2]rl.Vector2, ents: []$Entity, dt: f32) {
	for &e in ents {
		update_rigid_body(window_bounds, &e.body, dt)
		update_asteroid_shape(&e)
	}
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
