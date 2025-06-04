package asteroid
import rl "vendor:raylib"
import gl "vendor:raylib/rlgl"

Shape :: struct {
	points: [dynamic]rl.Vector2,
}

make_shape_from_poly :: proc(origin: rl.Vector2, sides: int, radius : f32 = 1.0, rotation: f32 = 0.0) -> (shape: Shape) {
	angle := 360.0 / f32(sides)
	for i in 0..<sides {
		append(&shape.points, extend_point(origin, f32(i) * angle + rotation, radius))
	}
	return
}

make_shape :: proc {
	make_shape_from_poly,
}


mean_shape :: proc(shape: ^Shape) -> (m := rl.Vector2(0)) {
	for &p in shape.points do m += p
	return m / f32(len(shape.points))
}

translate_shape :: proc(shape: ^Shape, translation: rl.Vector2, lower := rl.Vector2(0), upper := rl.Vector2(0)) {
	mean := mean_shape(shape)
	movement := clamp_vec(mean + translation, lower, upper) - mean
	for &p in shape.points {
		p += movement
	}
}

draw_shape_debug :: proc(s: ^Shape) {
	rl.DrawSplineLinear(raw_data(s.points), i32(len(s.points)), 2.0, rl.GREEN)
	rl.DrawLineEx(s.points[0], s.points[len(s.points) - 1], 2.0, rl.GREEN)
	
	rl.DrawCircleV(mean_shape(s), 2.0, rl.GREEN)
}

draw_shape_filled :: proc(s: ^Shape, color: rl.Color) {
	if len(s.points) < 3 do return
	
    gl.Begin(gl.TRIANGLES)
    gl.Color4ub(color.r, color.g, color.b, color.a)

    for i := 1; i < len(s.points) - 1; i += 1 {
        gl.Vertex2f(s.points[0].x, s.points[0].y)
        gl.Vertex2f(s.points[len(s.points) - i].x, s.points[len(s.points) - i].y)
        gl.Vertex2f(s.points[len(s.points) - i - 1].x, s.points[len(s.points) - i - 1].y)
    }

    gl.End()	
}
