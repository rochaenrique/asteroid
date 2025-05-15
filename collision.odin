package asteroid
import "core:fmt"
import rl "vendor:raylib"

Collision :: struct($A, $B: typeid) {
	a: ^A,
	b: ^B,
}

test_collision :: proc(a, b: ^$Entity) -> (coll: Collision(Entity, Entity), ok: bool) {
	ok = rl.Vector2Distance(a.center, b.center) < a.radius + b.radius
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

solve_impulse :: proc(collisions: [dynamic]Collision($Entity, Entity)) {
	THRESHHOLD :: 1.0
	
	for &col in collisions {
		// treating center as position
		// treating mass as proportional to radius
		using col
		normal := rl.Vector2Normalize(a.center - b.center)
		rvel := a.velocity - b.velocity
		speed := rl.Vector2DotProduct(rvel, normal)

		if speed >= 0 do continue

		restit := 1.0
		
		j := -2.0 *speed / (1/a.radius + 1/b.radius)
		impulse := normal * j

		if rl.Vector2Length(impulse) > THRESHHOLD {
			a.velocity += impulse / a.radius
			b.velocity -= impulse / b.radius
		}
		
		// for now no friction
	}
}
