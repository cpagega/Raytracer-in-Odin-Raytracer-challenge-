
package main

import "core:math"
import "core:thread"
import rl "vendor:raylib"
width: i32 = 1920
height: i32 = 1080
canvas: []rl.Color
render_complete: bool

main :: proc() {
	canvas = make([]rl.Color, width * height)
	defer delete(canvas)

	// Initialize Raylib window
	width: i32 = 1920
	height: i32 = 1080
	rl.InitWindow(width, height, "Raytracer")
	defer rl.CloseWindow()
	rl.SetTargetFPS(60)
	image := rl.GenImageColor(width, height, rl.BLACK)
	texture := rl.LoadTextureFromImage(image)
	rl.UnloadImage(image)
	defer rl.UnloadTexture(texture)
	// End Raylib window initialization

	// Begin rendering -
	// Because this is a CPU raytracer, the rendering is done outside the window loop,
	// there is no point trying to render with any kind of useable frame rate.
	render_complete = false
	render_thread := thread.create(render_thread_proc)
	render_start := rl.GetTime()
	thread.start(render_thread)
	texture_uploaded := false
	render_time: f64

	for !rl.WindowShouldClose() {
		rl.BeginDrawing()
		rl.ClearBackground(rl.BLACK)
		// Once the rendering thread is complete then draw the rendered scene once
		if render_complete {
			if !texture_uploaded {
				render_time = rl.GetTime() - render_start
				rl.UpdateTexture(texture, raw_data(canvas[:]))
				texture_uploaded = true
			}
			rl.DrawTexture(texture, 0, 0, rl.WHITE)
			rl.DrawText(
				rl.TextFormat("Total rendering time: %.2f seconds", render_time),
				20,
				20,
				24,
				rl.WHITE,
			)
			// while waiting for the scene to be rendered, display the elapsed time
		} else {
			elapsed := rl.GetTime() - render_start
			rl.DrawText(rl.TextFormat("Rendering...%.2f seconds", elapsed), 20, 20, 24, rl.WHITE)
		}
		rl.EndDrawing()
	}

	thread.join(render_thread)
	thread.destroy(render_thread)
}

render_thread_proc :: proc(t: ^thread.Thread) {
	// Floor
	floor := make_shape(.Plane)
	// Spheres
	middle := make_sphere()
	middle.transform = translate(-0.5, 0, 20.5)
	middle.material = material()
	middle.material.color = Color{0.1, 1, 0.5}
	middle.material.diffuse = 0.7
	middle.material.specular = 0.3

	right := make_sphere()
	right.transform = translate(1.5, 0.5, -0.5) * scale(0.5, 0.5, 0.5)
	right.material = material()
	right.material.color = Color{0.5, 1, 0.1}
	right.material.diffuse = 0.7
	right.material.specular = 0.3

	left := make_sphere()
	left.transform = translate(-1.5, 0.33, -0.75) * scale(0.33, 0.33, 0.33)
	left.material.color = Color{1, 0.8, 0.1}
	left.material.diffuse = 0.7
	left.material.specular = 0.3

	scene: Scene
	append(&scene.shapes, floor)
	append(&scene.shapes, middle)
	append(&scene.shapes, right)
	append(&scene.shapes, left)

	scene.light = point_light(point(-10, 10, -10), Color{1, 1, 1})

	camera := new_camera(f32(width), f32(height), math.PI / 3)
	camera.transform = view_transform(point(0, 1.5, -5), point(0, 1, 0), vector(0, 1, 0))

	render(camera, scene, &canvas)
	render_complete = true
}
