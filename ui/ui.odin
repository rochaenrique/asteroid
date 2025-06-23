package ui

import rl "vendor:raylib"
import vmem "core:mem/virtual"
import "base:runtime"

Alignment :: enum {
	Center,
	Top_Left,
	Absolute,
	Relative,

	Horizontal,
	Vertical,

	Top,
	Bottom,
	Left,
	Right,
}

Scaling :: enum {
	// Fill,
	Relative,
	Absolute, 
}

Layout :: struct {
	alignment: Alignment,
	scaling: Scaling,
	position: rl.Vector2,
	size: rl.Vector2,
}

Tree :: struct {
	root: ^Node,
	allocator: runtime.Allocator,
	arena: vmem.Arena,
}

Node :: struct {
	layout: Layout,
	color: rl.Color,
	
	content: union {
		[]Node,
		Text,
	},
}

Text :: struct {
	text: cstring,
	font_size, spacing: f32,
}

DEFAULT_SPACING : f32 : 1.0

@(private)
ui_tree: ^Tree

init :: proc() {
	ui_tree = new(Tree)
	err := vmem.arena_init_growing(&ui_tree.arena)
	ensure(err == nil)
	ui_tree.allocator = vmem.arena_allocator(&ui_tree.arena)
}

destroy :: proc() {
	vmem.arena_destroy(&ui_tree.arena)
	free(ui_tree)
}

root :: proc(children: ..Node) {
	ui_tree.root = new(Node, ui_tree.allocator)
	ui_tree.root^ = {
		content = make([]Node, len(children), ui_tree.allocator),
		color = rl.BLACK,
	}
	copy(ui_tree.root.content.([]Node), children)
}

parent_node :: proc(layout: Layout, color: rl.Color, children: ..Node) -> Node {
	node := new(Node, ui_tree.allocator)
	node^ = {
		layout = layout,
		content = make([]Node, len(children), ui_tree.allocator),
		color = color,
	}
	copy(node.content.([]Node), children)
	return node^
}

text_node :: proc(layout: Layout, color: rl.Color, text: Text) -> Node {
	node := new(Node, ui_tree.allocator)
	node^ = {
		layout = layout,
		content = text,
		color = color,
	}
	return node^
}

node :: proc {
	parent_node,
	text_node,
}

update :: proc() {
	ui_tree.root.layout = {
		position = rl.Vector2(0),
		size = rl.Vector2{
			f32(rl.GetScreenWidth()),
			f32(rl.GetScreenHeight()),
		},
	}

	for &child in ui_tree.root.content.([]Node) {
		update_node(&child, ui_tree.root.layout)
	}	
}

@(private)
update_node :: proc(node: ^Node, parent_layout: Layout) {
	if node == nil do return

	switch content in node.content {
	case []Node:
		if node.layout.scaling == .Relative {
			node.layout.size *= parent_layout.size
		}
	case Text:
		if node.layout.scaling == .Absolute {
			node.layout.size = rl.MeasureTextEx(rl.GetFontDefault(), content.text, content.font_size, content.spacing)
		}
	}
	
	switch node.layout.alignment {
	case .Center:
		node.layout.position = centered(node.layout, parent_layout)
		
	case .Top_Left:
		node.layout.position = parent_layout.position

	case .Absolute:
		// do nothing here
		
	case .Relative:
		node.layout.position = parent_layout.position + node.layout.position * parent_layout.size

	case .Horizontal:
		node.layout.position = rl.Vector2{
			parent_layout.position.x + node.layout.position.x * parent_layout.size.x,
			center(parent_layout, Axis.Y),
		}

	case .Vertical:
		node.layout.position = rl.Vector2{
			center(parent_layout, Axis.X),
			parent_layout.position.y + node.layout.position.y * parent_layout.size.y,
		}

	case .Top:
		node.layout.position = rl.Vector2{
			centered(node.layout, parent_layout, Axis.X),
			parent_layout.position.y,
		}

	case .Bottom:
		node.layout.position = rl.Vector2{
			centered(node.layout, parent_layout, Axis.X),
			edge_in_axis(node.layout, parent_layout, Axis.Y),
		}		

	case .Left:
		node.layout.position = rl.Vector2{
			parent_layout.position.x,
			centered(node.layout, parent_layout, Axis.Y),
		}

	case .Right:
		node.layout.position = rl.Vector2{
			edge_in_axis(node.layout, parent_layout, Axis.X),
			centered(node.layout, parent_layout, Axis.Y),
		}				
	}

	switch content in node.content {
	case []Node:
		for &child in content {
			update_node(&child, node.layout)
		}
	case Text:
		// do nothing here

	}
}

draw :: proc() {
	draw_node(ui_tree.root)
}

@(private)
draw_node :: proc(node: ^Node) {
	if node == nil do return

	switch content in node.content {
	case []Node:
		rl.DrawRectangleV(node.layout.position, node.layout.size, node.color)
		for &child in content {
			draw_node(&child)
		}		
	case Text:
		rl.DrawTextEx(rl.GetFontDefault(), content.text, node.layout.position, content.font_size, content.spacing, node.color)
	}	
}
