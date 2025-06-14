package asteroid
import rl "vendor:raylib"
import "core:math"

RESTITUTION : f32 : 0.3
SPEED_DAMAGE : f32 : 0.005
EXPLOSION_ENERGY :: 600.0

Collision :: struct {
	a: EntityId,
	b: EntityId,
	mtv: rl.Vector2,
}

update_collisions :: proc() {
	collisions := make([dynamic]Collision, context.temp_allocator)
	
	for i in 0..<game_entity_count() {
		a := game_get_entity(EntityId(i))
		(a != nil && !a.static) or_continue
		
		norms_a := shape_normals(&a.shape)
		for j in i+1..<game_entity_count() {
			b := game_get_entity(EntityId(j))
			(b != nil && !b.static) or_continue

			norms_b := shape_normals(&b.shape)
			ok, mtv := entity_shape_collision(&a.shape, &b.shape, norms_a, norms_b)
			if ok do append(&collisions, Collision{EntityId(i), EntityId(j), mtv})
		}
	}

	if len(collisions) > 0 { 
		solve_collisions(collisions)
		// when ODIN_DEBUG do draw_collisions(collisions)
		
		for &c in collisions {
			if p, ok := collision_point(&c); ok { 
				entity_explode(c.a, p)
				entity_explode(c.b, p)
			}
		}
	}
}

solve_collisions :: proc(collisions: [dynamic]Collision) {
	for &c in collisions {
		a := game_get_entity(c.a)
		b := game_get_entity(c.b)
		(a != nil && b != nil) or_continue
		
		inv_mass_a := 1.0 / a.body.mass
		inv_mass_b := 1.0 / b.body.mass
		total_inv_mass := inv_mass_a + inv_mass_b

		// correction := c.mtv / total_inv_mass
		// translate_shape(&c.a.shape, correction * inv_mass_a)
		// translate_shape(&c.b.shape, -correction * inv_mass_b)
		
		normal := rl.Vector2Normalize(c.mtv)

		relative_velocity := a.body.velocity - b.body.velocity
		speed := rl.Vector2DotProduct(relative_velocity, normal)

		(speed < 0) or_continue
		damage := abs(speed * SPEED_DAMAGE)
		a.health -= damage
		b.health -= damage

		impulse := normal * -(1.0 + RESTITUTION) * speed / total_inv_mass
		a.body.velocity += impulse * inv_mass_a
		b.body.velocity -= impulse * inv_mass_b
	}
}

entity_shape_collision :: proc(a, b: ^Shape, norms_a, norms_b: [dynamic]rl.Vector2,) -> (res := false, mtv: rl.Vector2) {
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

collision_point :: proc(c: ^Collision) -> (p: rl.Vector2, ok: bool) {
	a := game_get_entity(c.a)
	b := game_get_entity(c.b)
	center_a := shape_mean(&a.shape)
	center_b := shape_mean(&b.shape)
	
	ab := center_b - center_a
	distance := abs(rl.Vector2Length(ab))

	if distance <= 0.1 do return rl.Vector2(0), false
	
	return center_a + ab * (shape_radius(&a.shape, center_a) / distance), true
}

entity_explode :: proc(entityId: EntityId, origin: rl.Vector2) {
	entity := game_get_entity(entityId)
    if entity == nil do return

	if entity.health < 0 {
		defer game_destroy_entity(entityId)
		if len(entity.shape.points) < 4 do return
		
		vecs := entity.shape.points
		sides := len(vecs)
		
		for i := 0; i < sides; i += 1 {
			shard := Entity{
				color = rl.GRAY,
				static = false,
				health = 1.0,
				shape = Shape{make([dynamic]rl.Vector2, 0, 3)},
			}
			append(&shard.shape.points, origin, vecs[i], vecs[(i + 1) % sides])

			center := (origin + vecs[i] + vecs[(i + 1) % sides]) / 3.0
			direction := rl.Vector2Normalize(center - origin)        // the point from the origin to the shard center
			mass := shape_radius(&shard.shape, center)               // for now, mass is treated as proportianal to radius
			assert(mass != 0)
			k := EXPLOSION_ENERGY / mass  // how much of the "energy" the shard should have

			
			shard.body = Rigid_Body{
				velocity = direction * k, // calculate the velocity in each shard going away from the origin	
				force = rl.Vector2(0),
				mass = mass, 
			}
			
			game_add_entity(shard)
		}

	}
	
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

