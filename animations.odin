package asteroid

import ease "core:math/ease"
import rl "vendor:raylib"
import "core:time"

Anim_Data :: struct {
	entity: ^Entity,
	value: ^f32,
}

make_anim_data :: proc(entity: ^Entity, value := f32(0)) -> ^Anim_Data {
	data := new(Anim_Data)
	data^ = {
		entity = entity,
		value = new(f32),
	}
	data.value^ = value
	return data
}

destroy_anim_data :: proc(data: ^Anim_Data) {
	free(data.value)
	free(data)
}

entity_anim_color_on_start :: proc(flux: ^ease.Flux_Map(f32), data: rawptr) {
	anim_data := cast(^Anim_Data)data
	anim_data.entity.color = rl.RED
}

entity_anim_color_on_update :: proc(flux: ^ease.Flux_Map(f32), data: rawptr) {
	anim_data := cast(^Anim_Data)data
	tween := &flux.values[anim_data.value]
	anim_data.entity.color = rl.ColorLerp(rl.RED, rl.GRAY, f32(tween.progress))
}

entity_anim_color_on_complete :: proc(flux: ^ease.Flux_Map(f32), data: rawptr) {
	anim_data := cast(^Anim_Data)data
	destroy_anim_data(anim_data)
}

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
