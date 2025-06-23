package ui

import rl "vendor:raylib"

Axis :: enum {X, Y}

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

edge_in_axis :: proc(layout, parent: Layout, axis: Axis) -> f32 {
	return axis == .X ? parent.position.x + parent.size.x - layout.size.x :
		parent.position.y + parent.size.y - layout.size.y
}

