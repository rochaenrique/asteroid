package asteroid
import rl "vendor:raylib"
import "core:math"

Player_Mode :: enum {
	Drive, // player rotates according to mouse and thruster control, gun is disabled
	Sport, // gun points to mouse and there is basic 2 axis thruster control
	Park,  // precise side thrusters control and main thruster moves according to mouse
}

Player :: struct {
	id: EntityId,
	mode: Player_Mode,
	orbit_vel: f32,
}

ACC_DAMP :: 100.0
ORBIT_CONST :: 3.14 / 2

update_player :: proc(player: ^Player, dt: f32) {
	e := game_get_entity(player.id)
	assert(e != nil)


	#partial switch player.mode {
	case .Drive: {
		center := shape_mean(&e.shape)
		base := e.shape.points[0] - center // point of reference
		mouse_pos := rl.GetScreenToWorld2D(rl.GetMousePosition(), g.camera)
		to_mouse := mouse_pos - center
		
		angle := rl.Vector2Angle(base, to_mouse)
		cross := base.x * to_mouse.y - base.y * to_mouse.x // cross product to check angle sign
		if cross < 0 do angle = -angle

		// move towards the mouse
		force := ACC_DAMP * rl.Vector2Normalize(to_mouse)
		if rl.IsKeyDown(.W) do e.body.force += force
		if rl.IsKeyDown(.S) do e.body.force -= force

		// rotate the shape points
		for &p in e.shape.points {
			p = rl.Vector2Rotate(p - center, angle) + center
		}

		// orbit around the mouse with A and D
		orbit := ORBIT_CONST * dt
		if rl.IsKeyDown(.A) do player.orbit_vel += orbit
		if rl.IsKeyDown(.D) do player.orbit_vel -= orbit

		if math.abs(player.orbit_vel) > 0.001 {
			to_center := -to_mouse 
			translation := rl.Vector2Rotate(to_center, player.orbit_vel * dt) + to_mouse // rotate the vector from the mouse to the player
			
			for &p in e.shape.points {
				p += translation
			}
		}
	}
	}
}

