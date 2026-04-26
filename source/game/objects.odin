package game

import tiled "../tiled"
import "core:fmt"

Object :: struct {
	id:         int,
	x:          f32,
	y:          f32,
	width:      f32,
	height:     f32,
	properties: Object_Properties,
}

Object_Properties :: union {
	Object_Spawnpoint,
	Object_Transition,
	Object_Enemy,
}

Object_Spawnpoint :: struct {}

Object_Transition :: struct {}

Object_Enemy :: struct {
	hp:         int,
	enemy_name: string,
}

object_make :: proc(obj: tiled.Object) -> (result: Object) {
	result = Object {
		id     = obj.id,
		x      = obj.x,
		y      = obj.y,
		width  = f32(obj.width),
		height = f32(obj.height),
	}

	switch obj.type {
	case "spawnpoint":
		result.properties = Object_Spawnpoint{}
	case "transition":
		result.properties = Object_Transition{}
	case "enemy":
		result.properties = Object_Enemy {
			hp         = obj.properties["hp"].(int),
			enemy_name = obj.properties["enemy_name"].(string),
		}
	case:
		panic(fmt.tprintf("Unknown object type: %s", obj.type))
	}

	return result
}
