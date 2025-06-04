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

translate_shape :: proc(shape: ^Shape, translation: rl.Vector2, lower := rl.Vector2(-9999), upper := rl.Vector2(9999)) {
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

project_shape_to_axis :: proc(s: ^Shape, axis: rl.Vector2) -> (min: f32, max: f32) {
	min = rl.Vector2DotProduct(s.points[0], axis)
    max = min

    for i := 1; i < len(s.points); i += 1 {
        proj := rl.Vector2DotProduct(s.points[i], axis)
        if proj < min do min = proj
        else if proj > max do max = proj
    }
	return
}

shapes_overlap_axis :: proc(a, b: ^Shape, axis: rl.Vector2) -> (bool, f32) {
	a_min, a_max := project_shape_to_axis(a, axis)
	b_min, b_max := project_shape_to_axis(b, axis)
	
	if a_max < b_min || b_max < a_min do return false, 0

	return true, min(a_max, b_max) - max(a_min, b_min)
}

shape_normals :: proc(s: ^Shape) -> [dynamic]rl.Vector2 {
	normals := make([dynamic]rl.Vector2, 0, len(s.points), context.temp_allocator)
	for point, i in s.points {
        next := s.points[(i + 1) % len(s.points)]
        inject_at(&normals, i, rl.Vector2Normalize(perpendicular(next - point)))
     }
	
	return normals
}

