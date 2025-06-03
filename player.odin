package asteroid
import rl "vendor:raylib"
import "core:fmt"
import "core:math"

Player :: struct {
	body: Rigid_Body,
	radius, rotation: f32,
	sides: i32,
	shape: Shape,
}

make_player :: proc(window_size: rl.Vector2) -> (p: Player) {
	_radius := window_size.x * 0.015
	p = {
		body = Rigid_Body {
			position = window_size * 0.5,
			mass = _radius,
		},
		radius = _radius,
		rotation = 0,
		sides = 3,
	}
	shape_from_poly(&p.shape, p.body.position, p.sides, p.radius, p.rotation)
	return
}

draw_player_debug :: proc(p: ^Player) {
	rl.DrawLineV(p.body.position, extend_point(p.body.position, p.rotation, 5 * p.radius), rl.GREEN)
	rl.DrawSplineLinear(raw_data(p.shape.points), i32(len(p.shape.points)), 1.0, rl.GREEN)
}

draw_player :: proc(p: ^Player) {
	rl.DrawPoly(p.body.position, p.sides, p.radius, p.rotation, rl.RED)
	when ODIN_DEBUG do draw_player_debug(p)
}

update_player :: proc(window_bounds: ^[2]rl.Vector2, p: ^Player, dt: f32) {

	FORWARD :: rl.Vector2{1, 0}
	BACKWARD :: rl.Vector2{-1, 0}

	movement: rl.Vector2
	
	if rl.IsKeyPressed(.W) do movement += 10 * FORWARD 
	if rl.IsKeyPressed(.S) do movement += 10 * BACKWARD
	if rl.IsKeyPressedRepeat(.W) do movement += 10* FORWARD 
	if rl.IsKeyPressedRepeat(.S) do movement += 10* BACKWARD

	if rl.IsKeyPressed(.Q) do p.rotation += -5
	if rl.IsKeyPressed(.E) do p.rotation +=  5 
	if rl.IsKeyPressedRepeat(.Q) do p.rotation += -5
	if rl.IsKeyPressedRepeat(.E) do p.rotation +=  5
	
	if rl.IsKeyPressed(.A) do p.rotation += -10
	if rl.IsKeyPressed(.D) do p.rotation +=  10
	if rl.IsKeyPressedRepeat(.A) do p.rotation += -10
	if rl.IsKeyPressedRepeat(.D) do p.rotation +=  10

	if p.rotation > 360 do p.rotation -= 360
	if p.rotation < -360 do p.rotation += 360

	p.body.velocity += rl.Vector2Rotate(movement, math.to_radians(p.rotation))
	update_rigid_body(window_bounds, &p.body, dt)
	shape_from_poly(&p.shape, p.body.position, p.sides, p.radius, p.rotation)
	
}

player_collisions :: proc(player: ^Player, ents: []$Entity) {
	for &e in ents {
		if collided(player, &e) do fmt.printfln("Collision with %g!", e.body.position)
	}
}	
