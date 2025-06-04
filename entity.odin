package asteroid

import rl "vendor:raylib"
import "core:math/rand"

Entity :: struct {
	body: Rigid_Body,
	shape: Shape,
	color: rl.Color,
}

make_entity_poly :: proc(position: rl.Vector2, sides: int, radius: f32, c := rl.GRAY) -> Entity {
	return {
		body = make_rigid_body(),
		shape = make_shape(position, sides, radius, 0),
		color = c,
	}
}

make_entity_rand :: proc(lower, upper: rl.Vector2, c := rl.GRAY) -> Entity {
	sides := 5+rand.int_max(9)
	body := make_rigid_body_rand(lower, upper)
	return {
		body = body,
		shape = make_shape(rand_vec2(lower, upper), sides, body.mass, 0),
		color = c,
	}
}

make_entity :: proc {
	make_entity_poly,
	make_entity_rand,
}

make_entities :: proc(entities: ^[dynamic]Entity, num: int, bounds: ^Window_Bounds, color: rl.Color) {
	for i := 0; i < num; i += 1 {
		append(entities, make_entity(bounds.lower, bounds.upper, color))
	}
}

draw_entity :: proc(e: ^Entity) {
	when ODIN_DEBUG do draw_shape_debug(&e.shape)
	draw_shape_filled(&e.shape, e.color)
}

draw_entities :: proc(entities: [dynamic]Entity) {
	for &e in entities do draw_entity(&e)
}

update_entity :: proc(e: ^Entity, dt: f32, bounds: ^Window_Bounds) {
	resolve_rigid_body(&e.body, dt)
	translate_shape(&e.shape, e.body.velocity * dt, bounds.lower, bounds.upper)
}

update_entities :: proc(entities: [dynamic]Entity, dt: f32, bounds: ^Window_Bounds) {
	update_collisions(entities)
	for &e in entities {
		update_entity(&e, dt, bounds)
	}
}
