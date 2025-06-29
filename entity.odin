package asteroid

import rl "vendor:raylib"
import "core:math/rand"

MIN_SHAPE_POINTS :: 7
MAX_SHAPE_POINTS :: 10

EntityId :: distinct int

Entity :: struct {
	body: Rigid_Body,
	shape: Shape,
	color: rl.Color,
	static: bool,
	health: f32,
}

make_entity_poly :: proc(position: rl.Vector2, sides: int, radius: f32, static := false, health := f32(1), color := rl.GRAY) -> Entity {
	return {
		body = make_rigid_body(),
		shape = make_shape(position, sides, radius, 0),
		static = static,
		color = color,
		health = health,
	}
}

make_entity_rand :: proc(lower, upper: rl.Vector2, static := false, health := f32(1), color := rl.GRAY) -> Entity {
	sides := MIN_SHAPE_POINTS + rand.int_max(MAX_SHAPE_POINTS)
	body := make_rigid_body_rand(lower, upper)
	return {
		body = body,
		shape = make_shape(rand_vec2(lower, upper), sides, body.mass, 0),
		static = static,
		color = color,
		health = health,
	}
}

make_entity :: proc {
	make_entity_poly,
	make_entity_rand,
}

delete_entity :: proc(e: ^Entity) {
	delete_shape(&e.shape)
}

draw_entity :: proc(id: EntityId) {
	if e := game_get_entity(id); e != nil {
		color := rl.ColorLerp(e.color, rl.RED, 1.0 - e.health)
		draw_shape_filled(&e.shape, color)

		when ODIN_DEBUG do draw_shape_debug(&e.shape)
	}
}

update_entity :: proc(id: EntityId, dt: f32, bounds: ^Window_Bounds) {
	if e := game_get_entity(id); e != nil && !e.static {
		resolve_rigid_body(&e.body, dt)
		translate_shape(&e.shape, e.body.velocity * dt, bounds.lower, bounds.upper)
	}
}

update_entities :: proc(dt: f32, bounds: ^Window_Bounds) {
	update_collisions()
	for i in 0..<game_entity_count() {
		update_entity(EntityId(i), dt, bounds)
	}
}
