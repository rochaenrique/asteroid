package asteroid
import rl "vendor:raylib"
import "core:math"

Collision :: struct {
	a: ^Entity,
	b: ^Entity,
	mtv: rl.Vector2,
}

draw_collisions :: proc(collisions: [dynamic]Collision) {
	for &c in collisions {
		// animate_entity_death(c.a)
		// animate_entity_death(c.b)
		if p, ok := collision_point(&c); ok {
			animate_point(p)
		}
	}
}

collision_point :: proc(c: ^Collision) -> (p: rl.Vector2, ok: bool) {
	center_a := shape_mean(&c.a.shape)
	center_b := shape_mean(&c.b.shape)
	
	ab := center_b - center_a
	distance := abs(rl.Vector2Length(ab))

	if distance <= 0.1 do return rl.Vector2(0), false
	
	return center_a + ab * (shape_radius(&c.a.shape, center_a) / distance), true
}

entity_shape_collision :: proc(
	a: ^Shape,
	norms_a: [dynamic]rl.Vector2,
	b: ^Shape,
	norms_b: [dynamic]rl.Vector2,
) -> (res := false, mtv: rl.Vector2) {
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
	
	direction := shape_mean(a) - shape_mean(b)
	if rl.Vector2DotProduct(direction, mtv) < 0 do mtv *= -1
	
	return true, mtv * smallest_overlap
}

update_collisions :: proc(ents: [dynamic]Entity) {
	collisions := make([dynamic]Collision, context.temp_allocator)
	for i in 0..<len(ents) {
		a := &ents[i]
		(!a.static) or_continue
		
		norms_a := shape_normals(&a.shape)
		for j in i+1..<len(ents) {
			b := &ents[j]
			(!b.static) or_continue

			norms_b := shape_normals(&b.shape)
			ok, mtv := entity_shape_collision(&a.shape, norms_a, &b.shape, norms_b)
			if ok do append(&collisions, Collision{a, b, mtv})
		}
	}

	if len(collisions) > 0 { 
		solve_collisions(collisions)
		when ODIN_DEBUG do draw_collisions(collisions)
	}
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
