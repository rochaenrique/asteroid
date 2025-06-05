package asteroid
import "core:math"
import "core:math/rand"
import rl "vendor:raylib"

rand_vec2 :: #force_inline proc(lower := rl.Vector2(0), upper := rl.Vector2(100)) -> rl.Vector2 {
	return {
		rand.float32_range(lower.x, upper.x), 
		rand.float32_range(lower.x, upper.y),
	}
}

clamp_val :: #force_inline proc(v, minimum, maximum: f32) -> f32 {
	return minimum if v > maximum else maximum if v < minimum else v
}

clamp_vec :: #force_inline proc(pos, minimum, maximum: rl.Vector2) -> rl.Vector2 {
	return {
		clamp_val(pos.x, minimum.x, maximum.x),
		clamp_val(pos.y, minimum.y, maximum.y),
	}
}

extend_point :: proc(origin: rl.Vector2, angle, radius: f32) -> rl.Vector2 {
	return origin + rl.Vector2Rotate(rl.Vector2{1, 0}, math.to_radians(angle)) * radius
}

in_bounds :: proc(pos: rl.Vector2, minimum, maximum: rl.Vector2) -> bool {
	return pos.x < minimum.x || pos.x > maximum.x ||
		pos.y < minimum.y || pos.y > maximum.y		
}

perpendicular :: proc(v: rl.Vector2) -> rl.Vector2 {
	return { -v.y, v.x }
}

index_at :: proc(arr: ^[dynamic]$T, el: ^T) -> (index := -1, res := false) {
	for &e, i in arr {
		if el == &e do return i, true
	}
	return 
}

