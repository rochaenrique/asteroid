package asteroid
import rl "vendor:raylib"

Shape :: struct {
	points: [dynamic]rl.Vector2,
}

make_shape_from_poly :: proc(origin: rl.Vector2, sides: i32, radius, rotation: f32) -> (shape: Shape) {
	angle := 360.0 / f32(sides)
	for i in 0..<sides {
		append(&shape.points, extend_point(origin, f32(i) * angle + rotation, radius))
	}
	return
}

set_shape_from_poly :: proc(shape: ^Shape, origin: rl.Vector2, sides: i32, radius, rotation: f32) {
	angle := 360.0 / f32(sides)
	clear(&shape.points)
	for i in 0..<sides {
		append(&shape.points, extend_point(origin, f32(i) * angle + rotation, radius))
	}
	resize(&shape.points, sides)
}

shape_from_poly :: proc {
	make_shape_from_poly,
	set_shape_from_poly,
}
