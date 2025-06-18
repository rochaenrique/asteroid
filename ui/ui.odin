package ui

import rl "vendor:raylib"

Text :: struct {
	text: cstring,
	font_size, spacing: f32,
}

DEFAULT_SPACING : f32 : 1.0

draw_text_centered_pos :: proc(text: cstring, font_size: f32, position: rl.Vector2, spacing := f32(1)) {
	measure := rl.MeasureTextEx(rl.GetFontDefault(), text, font_size, spacing)
	adjusted_pos := position - measure / 2
	rl.DrawTextEx(rl.GetFontDefault(), text, adjusted_pos, font_size, DEFAULT_SPACING, rl.BLUE)
}

draw_text_centered_container :: proc(text: cstring, size: f32, rectangle: rl.Rectangle, spacing := f32(1)) {
	draw_text_centered_pos(text, size, rectangle_center(rectangle))
}

draw_text_centered :: proc{
	draw_text_centered_pos,
	draw_text_centered_container,
}

draw_text_stack :: proc(position: rl.Vector2, padding: f32, texts: ..Text) {
	full_height := padding * f32(len(texts) - 1)
	for &t in texts {
		measure := rl.MeasureTextEx(rl.GetFontDefault(), t.text, t.font_size, t.spacing)
		full_height += measure.y
	}

	curr_y := position.y - full_height / 2
	for &t in texts {
		measure := rl.MeasureTextEx(rl.GetFontDefault(), t.text, t.font_size, t.spacing)
		
		adjusted := rl.Vector2{position.x - measure.x / 2, curr_y}
		rl.DrawTextEx(rl.GetFontDefault(), t.text, adjusted, t.font_size, t.spacing, rl.BLUE)
		
		curr_y += measure.y + padding
	}
}
