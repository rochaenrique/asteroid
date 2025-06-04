package asteroid
import rl "vendor:raylib"

update_player_rotate :: proc(p: ^Entity, dt: f32) {

	// FORWARD :: rl.Vector2{1, 0}
	// BACKWARD :: rl.Vector2{-1, 0}

	// movement: rl.Vector2
	
	// if rl.IsKeyPressed(.W) do movement += 10 * FORWARD 
	// if rl.IsKeyPressed(.S) do movement += 10 * BACKWARD
	// if rl.IsKeyPressedRepeat(.W) do movement += 10* FORWARD 
	// if rl.IsKeyPressedRepeat(.S) do movement += 10* BACKWARD

	// if rl.IsKeyPressed(.Q) do p.rotation += -5
	// if rl.IsKeyPressed(.E) do p.rotation +=  5 
	// if rl.IsKeyPressedRepeat(.Q) do p.rotation += -5
	// if rl.IsKeyPressedRepeat(.E) do p.rotation +=  5
	
	// if rl.IsKeyPressed(.A) do p.rotation += -10
	// if rl.IsKeyPressed(.D) do p.rotation +=  10
	// if rl.IsKeyPressedRepeat(.A) do p.rotation += -10
	// if rl.IsKeyPressedRepeat(.D) do p.rotation +=  10

	// if p.rotation > 360 do p.rotation -= 360
	// if p.rotation < -360 do p.rotation += 360

	// p.body.velocity += rl.Vector2Rotate(movement, math.to_radians(p.rotation))
	// update body and shape
}

update_player :: proc(p: ^Entity, dt: f32) {
	UP	  :: rl.Vector2{ 0, -1}
	DOWN  :: rl.Vector2{ 0,  1}
	RIGHT :: rl.Vector2{ 1,  0}
	LEFT  :: rl.Vector2{-1,  0}

	movement := rl.Vector2(0)

	if rl.IsKeyPressed(.W) do movement += UP 
	if rl.IsKeyPressed(.S) do movement += DOWN

	if rl.IsKeyPressed(.A) do movement += LEFT
	if rl.IsKeyPressed(.D) do movement += RIGHT

	p.body.velocity += movement * dt * 1000
}
