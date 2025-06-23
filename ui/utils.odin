package ui

import rl "vendor:raylib"

Axis :: enum {X, Y}

// ==================================================
// find the center of a layout or rectangle
// ==================================================

rectangle_center :: proc(rect: rl.Rectangle) -> rl.Vector2 {
	return rl.Vector2{ rect.x + rect.width / 2, rect.y - rect.height / 2}
}

layout_center :: proc(layout: Layout) -> rl.Vector2 {
	return layout.position + layout.size / 2
}

axis_center :: proc(layout: Layout, axis: Axis) -> f32 {
	return axis == .X ? layout.position.x + layout.size.x / 2 :
		layout.position.y + layout.size.y / 2
}

center :: proc{
	rectangle_center,
	layout_center,
	axis_center,
}

// ==================================================
// find the position of centered layout at the center of a parent
// ==================================================

centered_in_parent :: proc(layout, parent: Layout) -> rl.Vector2 {
	return center(parent) - layout.size / 2
}

centered_in_axis :: proc(layout, parent: Layout, axis: Axis) -> f32 {
	return axis == .X ? axis_center(parent, .X) - layout.size.x / 2 :
		axis_center(parent, .Y) - layout.size.y / 2
}

centered :: proc {
	centered_in_parent,
	centered_in_axis,
}

// ==================================================
// find the position of a layout at the edge of a parent
// ==================================================

edge_in_axis :: proc(layout, parent: Layout, axis: Axis) -> f32 {
	return axis == .X ? parent.position.x + parent.size.x - layout.size.x :
		parent.position.y + parent.size.y - layout.size.y
}

// ==================================================
// Conversion functions
// ==================================================

rect_to_layout :: proc(rect: rl.Rectangle) -> Layout {
	return {
		position = rl.Vector2{ rect.x, rect.y },
		size = rl.Vector2{ rect.width, rect.height },
	}
}

layout_to_recto :: proc(layout: Layout) -> rl.Rectangle {
	return {
		x = layout.position.x,
		y = layout.position.y,
		width = layout.size.x,
		height = layout.size.y,
	}
}

// ==================================================
// Text utils
// ==================================================

text_measure :: proc(text: Text, size: f32) -> rl.Vector2 {
	return rl.MeasureTextEx(rl.GetFontDefault(), text.text, size, text.spacing)
}

