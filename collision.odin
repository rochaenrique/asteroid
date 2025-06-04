package asteroid
import rl "vendor:raylib"
import "core:math"

Collision :: struct {
	a: ^Entity,
	b: ^Entity,
	mtv: rl.Vector2,
}

entity_shape_collision :: proc(a: ^Shape, norms_a: [dynamic]rl.Vector2, b: ^Shape, norms_b: [dynamic]rl.Vector2) -> (res := false, mtv: rl.Vector2) {
	smallest_overlap := f32(math.F32_MAX)
	
	for axis in norms_a {
		ok, overlap := shapes_overlap_axis(a, b, axis)
		if !ok do return
		
		if rl.Vector2Length(overlap) < smallest_overlap {
			smallest_overlap = overlap
			mtv = axis
		}
	}
	
	for axis in norms_b {
		ok, overlap := shapes_overlap_axis(a, b, axis)
		if !ok do return
		
		if rl.Vector2Length(overlap) < smallest_overlap {
			smallest_overlap = overlap
			mtv = axis
		}
	}
	
	direction := mean_shape(a) - mean_shape(b)
	if rl.Vector2DotProduct(direction, mtv) < 0 do mtv *= -1
	
	return true, mtv * smallest_overlap
}

update_collisions :: proc(ents: [dynamic]Entity) {
	collisions := make([dynamic]Collision, context.temp_allocator)
	for &a in ents {
		norms_a := shape_normals(&a.shape)
		for &b in ents {
			(&a != &b) or_continue

			norms_b := shape_normals(&b.shape)
			ok, mtv := entity_shape_collision(&a.shape, norms_a, &b.shape, norms_b)
			if ok do append(&collisions, Collision{&a, &b, mtv})
		}
	}

	solve_collisions(collisions)
}

solve_collisions :: proc(collisions: [dynamic]Collision) {
	RESTITUTION : f32 : 0.5
	
	for c in collisions {
		inv_mass_a := 1.0 / c.a.body.mass
		inv_mass_b := 1.0 / c.b.body.mass
		total_inv_mass := inv_mass_a + inv_mass_b

		// correction := c.mtv / total_inv_mass
		// translate_shape(&c.a.shape, correction * inv_mass_a)
		// translate_shape(&c.b.shape, -correction * inv_mass_b)
		
		normal := rl.Vector2Normalize(c.mtv)

		relative_velocity := c.a.body.velocity - c.b.body.velocity
		speed := rl.Vector2DotProduct(relative_velocity, normal)

		(speed < 0) or_continue
		
		impulse := normal * -(1.0 + RESTITUTION) * speed / total_inv_mass
		c.a.body.velocity += impulse * inv_mass_a
		c.b.body.velocity -= impulse * inv_mass_b
	}
}
