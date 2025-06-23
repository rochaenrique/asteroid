package ui

import rl "vendor:raylib"
import vmem "core:mem/virtual"
import "base:runtime"

Alignment :: enum {
	Center,		// centered inside the parent container
	Top_Left,	// position is equal to the parents top left corner
	Absolute,	// use specified position in pixels of screen
	Relative,	// x and y are scaling factors of parent space

	Horizontal,	// Center-y and x is scaling factor of parent space
	Vertical,	// Center-x and y is scaling factor of parent space

	Top,		// Center-x in the top edge
	Bottom,		// Center-x in the bottom edge
	Left,		// Center-y to the left edge
	Right,		// Center-y to the right edge
}

Scaling :: enum {
	Relative,	// size acts as a scaling factor of the parent
	Fill,		// fill the parent container, ignoring overflow
	Max_Width,	// max width, capping at height overflow
	Max_Height,	// max height, capping at width overflow
	Absolute,	// use the specified size in pixels
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
	spacing: f32,
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

	switch &content in node.content {
	case []Node:
		switch node.layout.scaling {
		case .Relative: node.layout.size *= parent_layout.size
		case .Fill: node.layout.size = parent_layout.size
		case .Max_Width: unimplemented()
		case .Max_Height: unimplemented()
		case .Absolute: // do nothing
		}
	case Text:
		switch node.layout.scaling {
		case .Relative:
			node.layout.size = text_measure(content, node.layout.size.y * parent_layout.size.y)
			
		case .Fill: // text height will be maximized on parent container, ignoring overflow
			node.layout.size = text_measure(content, parent_layout.size.y)

		case .Max_Width: unimplemented()
		case .Max_Height: unimplemented()
			
		case .Absolute: // Y of size is used in font_size units, X adjusted accordingly
			node.layout.size = text_measure(content, node.layout.size.y)
		}
	}
	
	switch node.layout.alignment {
	case .Center:
		node.layout.position = centered(node.layout, parent_layout)
		
	case .Top_Left:
		node.layout.position = parent_layout.position

	case .Absolute: // do nothing here
		
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
	case Text: // do nothing here
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
		rl.DrawTextEx(rl.GetFontDefault(), content.text, node.layout.position, node.layout.size.y, content.spacing, node.color)
	}	
}
