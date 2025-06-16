package asteroid
import rl "vendor:raylib"
import "core:math"

ACC_CONST   :: 150  // initial step acceleration
ACC_DAMP    :: 0.99 // coeficiente when not moving
ORBIT_CONST :: 3.14 / 3 // initial orbit (rad/s^2) acceleration
ORBIT_DAMP  :: 0.96 // coeficient when not orbiting

PARK_SLOW   :: 0.5

BULLET_ACC  :: 7e4 // initial bullet acceleration
BULLET_SIZE :: 2.5 // size in world pixels
BULLET_HLTH :: 0.5 // health out of one
BULLET_OFFS :: 1.05 // offset multiplier of where to place
BULLET_CLR  :: rl.YELLOW

Player_Mode :: enum {
	Drive, // player rotates according to mouse and thruster control, gun is disabled
	Sport, // gun points to mouse and there is basic 2 axis thruster control
	Park,  // precise side thrusters control and main thruster moves according to mouse
}

Player :: struct {
	id: EntityId,
	mode: Player_Mode,
	orbit_vel: f32, // orbit angular velocity (rad/s)
}

update_player :: proc(player: ^Player, dt: f32) {
	e := game_get_entity(player.id)
	assert(e != nil)

	if player.mode == .Park {
		UP    :: rl.Vector2{ 0,  1}
		DOWN  :: rl.Vector2{ 0, -1}
		RIGHT :: rl.Vector2{ 1,  0}
		LEFT  :: rl.Vector2{-1,  0}
		
		// regular world move
		if rl.IsKeyDown(.W) do e.body.force += PARK_SLOW * ACC_CONST * DOWN
		if rl.IsKeyDown(.S) do e.body.force += PARK_SLOW * ACC_CONST * UP
		
		if rl.IsKeyDown(.A) do e.body.force += PARK_SLOW * ACC_CONST * LEFT
		if rl.IsKeyDown(.D) do e.body.force += PARK_SLOW * ACC_CONST * RIGHT
		
		return
	}

	center := shape_mean(&e.shape)
	base := e.shape.points[0] - center // point of reference
	mouse_pos := rl.GetScreenToWorld2D(rl.GetMousePosition(), g.camera)
	to_mouse := mouse_pos - center
	angle := rl.Vector2Angle(base, to_mouse)
	cross := base.x * to_mouse.y - base.y * to_mouse.x // cross product to check angle sign
	if cross < 0 do angle = -angle

	// rotate the shape points
	for &p in e.shape.points {
		p = rl.Vector2Rotate(p - center, angle) + center
	}

	normal := rl.Vector2Normalize(to_mouse)

	if player.mode == .Drive { 
		// move towards the mouse
		if rl.IsKeyDown(.W) do e.body.force += ACC_CONST * normal
		if rl.IsKeyDown(.S) do e.body.force -= ACC_CONST * normal

		// damp the movement if there is none
		if !rl.IsKeyDown(.W) && !rl.IsKeyDown(.W) {
			e.body.velocity *= ACC_DAMP
		}

		// orbit around the mouse with A and D
		if rl.IsKeyDown(.A) do player.orbit_vel += ORBIT_CONST * dt
		if rl.IsKeyDown(.D) do player.orbit_vel -= ORBIT_CONST * dt

		// damp the orbit there is none
		if !rl.IsKeyDown(.A) && !rl.IsKeyDown(.D) {
			player.orbit_vel *= ORBIT_DAMP
		}

		if math.abs(player.orbit_vel) > 0.001 {
			// rotate the vector from the mouse to the player
			to_center := -to_mouse
			translation := rl.Vector2Rotate(to_center, player.orbit_vel * dt) + to_mouse 
			
			for &p in e.shape.points {
				p += translation
			}
		}
	} else if player.mode == .Sport { 
		radius := shape_radius(&e.shape, center)
		
		if rl.IsKeyPressed(.SPACE) {
			bullet := make_entity_poly( // create bullet besides player
				center + (normal * radius * BULLET_OFFS), 
				3,
				BULLET_SIZE,
				false,
				BULLET_HLTH,
				BULLET_CLR)
			
			bullet.body.velocity = BULLET_ACC * dt * normal * bullet.body.mass 
			id := game_add_entity(bullet)
			animate_entity_death_timed(id, 1000) // 1000ms timer to death 
		}
	}
}
