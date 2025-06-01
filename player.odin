package asteroid

import rl "vendor:raylib"
// import "core:fmt"
import "core:math"

Player :: struct {
	body: Rigid_Body,
	radius, rotation: f32,
}

make_player :: proc(window_size: rl.Vector2) -> Player {
	_radius := window_size.x * 0.015
	return {
		body = Rigid_Body {
			position = window_size * 0.5,
			mass = _radius,
		},
		radius = _radius,
		rotation = 0,
	}
}

draw_player :: proc(player: ^Player) {
	rl.DrawPoly(player.body.position, 3, player.radius, player.rotation, rl.RED)
	end := player.body.position + rl.Vector2Rotate(rl.Vector2{1, 0}, math.to_radians(player.rotation)) * 10 * player.radius
	rl.DrawLineV(player.body.position, end, rl.GREEN)
}

update_player :: proc(window_bounds: ^[2]rl.Vector2, player: ^Player, dt: f32) {

	FORWARD :: rl.Vector2{1, 0}
	BACKWARD :: rl.Vector2{-1, 0}

	movement: rl.Vector2
	
	if rl.IsKeyPressed(.W) do movement += 10 * FORWARD 
	if rl.IsKeyPressed(.S) do movement += 10 * BACKWARD
	if rl.IsKeyPressedRepeat(.W) do movement += 10* FORWARD 
	if rl.IsKeyPressedRepeat(.S) do movement += 10* BACKWARD

	if rl.IsKeyPressed(.Q) do player.rotation += -5
	if rl.IsKeyPressed(.E) do player.rotation +=  5 
	if rl.IsKeyPressedRepeat(.Q) do player.rotation += -5
	if rl.IsKeyPressedRepeat(.E) do player.rotation +=  5
	
	if rl.IsKeyPressed(.A) do player.rotation += -10
	if rl.IsKeyPressed(.D) do player.rotation +=  10
	if rl.IsKeyPressedRepeat(.A) do player.rotation += -10
	if rl.IsKeyPressedRepeat(.D) do player.rotation +=  10

	if player.rotation > 360 do player.rotation -= 360
	if player.rotation < -360 do player.rotation += 360

	player.body.velocity += rl.Vector2Rotate(movement, math.to_radians(player.rotation))
	update_rigid_body(window_bounds, &player.body, dt)
}

player_collisions :: proc(player: ^Player, ents: []$Entity) {
}	
