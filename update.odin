package asteroid
import rl "vendor:raylib"

Collision :: struct {
	a: ^Entity,
	b: ^Entity,
}

collided :: proc(a: ^Entity, b: ^Entity) -> bool {
	i := 0
	for i < len(a.shape.points) {
		if rl.CheckCollisionPointPoly(a.shape.points[i], raw_data(b.shape.points), i32(len(b.shape.points))) do break
	}
	return i < len(a.shape.points)
}

test_collision :: proc(a: ^Entity, b: ^Entity) -> (coll: Collision, ok: bool) {
	ok = collided(a, b)
	if ok do coll = Collision{a, b}
	return
}

update_collisions :: proc(ents: [dynamic]Entity) {
	collisions := make([dynamic]Collision, context.temp_allocator)
	for &a in ents {
		for &b in ents {
			(&a != &b) or_continue
			if coll, ok := test_collision(&a, &b); ok do append(&collisions, coll)
		}
	}

	solve_impulse(collisions)
}

solve_impulse :: proc(collisions: [dynamic]Collision) {
	THRESHHOLD :: 1.0
	RESTITUTION :: 0.5
	
	// for &c in collisions {
		// treating center as position
		// treating mass as proportional to radius
		// abody : ^Rigid_Body = &c.a.body
		// bbody : ^Rigid_Body = &c.b.body
		
		// normal := rl.Vector2Normalize(abody.position - bbody.position)
		// rvel := abody.velocity - bbody.velocity
		// speed := rl.Vector2DotProduct(rvel, normal)

		// if speed >= 0 do continue

		// j := -(RESTITUTION + THRESHHOLD) * speed / (1/abody.mass + 1/bbody.mass)
		// impulse := normal * j

		// if rl.Vector2Length(impulse) > THRESHHOLD {
		// 	abody.velocity += impulse / abody.mass
		// 	bbody.velocity -= impulse / abody.mass
		// }
		// for now no friction
	// }
}
