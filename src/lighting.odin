package main

Light :: struct {
	position:  vec4,
	intensity: Color,
}


point_light :: proc(position: vec4, intensity: Color) -> Light {
	return {position = position, intensity = intensity}
}
