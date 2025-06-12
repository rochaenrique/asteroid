package asteroid

import ease "core:math/ease"
import rl "vendor:raylib"
import "core:time"
import "core:fmt"

Anim_Data :: struct($T: typeid) {
	ptr: ^T,
	value: ^f32,
}

make_anim_data :: proc(ptr: ^$T, value := f32(0)) -> ^Anim_Data(T) {
	data := new(Anim_Data(T))
	data^ = {
		ptr = ptr,
		value = new(f32),
	}
	data.value^ = value
	return data
}

destroy_anim_data :: proc(data: ^Anim_Data($T)) {
	free(data.value)
	free(data)
}

// ---------------------------------------------------------------------------
// Entity Death Animation
// ---------------------------------------------------------------------------

animate_entity_death :: proc(e: ^Entity) {
	// red fade -> destroy
	anim_data := make_anim_data(e)
	duration := 1 * time.Second
	tween := ease.flux_to(&g.anims, anim_data.value, 10, .Exponential_Out, duration)
	
	tween.data = anim_data
	tween.on_start = entity_anim_color_on_start
	tween.on_update = entity_anim_color_on_update
	tween.on_complete = entity_anim_color_on_complete
	
	ease.flux_tween_init(tween, duration)
}

entity_anim_color_on_start :: proc(flux: ^ease.Flux_Map(f32), data: rawptr) {
	anim_data := cast(^Anim_Data(Entity))data
	anim_data.ptr.color = rl.RED
}

entity_anim_color_on_update :: proc(flux: ^ease.Flux_Map(f32), data: rawptr) {
	anim_data := cast(^Anim_Data(Entity))data
	tween := &flux.values[anim_data.value]
	anim_data.ptr.color = rl.ColorLerp(rl.RED, rl.GRAY, f32(tween.progress))
}

entity_anim_color_on_complete :: proc(flux: ^ease.Flux_Map(f32), data: rawptr) {
	anim_data := cast(^Anim_Data(Entity))data
	destroy_anim_data(anim_data)
}

// ---------------------------------------------------------------------------
// Glowing point animation
// ---------------------------------------------------------------------------
animate_point :: proc(position: rl.Vector2, ms : i64 = 1000) {
	// red fade -> destroy
	radius := rl.GetScreenToWorld2D(g.window_bounds.upper, g.camera).y * 0.01
	
	entity := game_create_entity(position, 10, radius, true, rl.GREEN)
	anim_data := make_anim_data(entity)
	duration := time.Millisecond * cast(time.Duration)ms 

	fmt.printfln("Collided! Drawing at point: %g", position)
	
	tween := ease.flux_to(&g.anims, anim_data.value, 10, .Exponential_Out, duration)
	
	tween.data = anim_data
	tween.on_complete = point_anim_on_complete
	
	ease.flux_tween_init(tween, duration)
}

point_anim_on_complete :: proc(flux: ^ease.Flux_Map(f32), data: rawptr) {
	anim_data := cast(^Anim_Data(Entity))data
	game_destroy_entity(anim_data.ptr)
	destroy_anim_data(anim_data)
}

