package ui

import rl "vendor:raylib"

rectangle_center :: proc(rect: rl.Rectangle) -> rl.Vector2 {
	return rl.Vector2{ rect.x + rect.width / 2, rect.y - rect.height / 2}
}
