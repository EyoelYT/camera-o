package main

import "core:fmt"
import "core:strings"
import "core:os"
import sdl "vendor:sdl3"

Window :: struct {
    name: string,
    x: i32,
    y: i32,
    w: i32,
    h: i32,
    flags: sdl.WindowFlags,
    on_top: bool,
    bordered: bool
}

Camera :: struct {
    camera_id: sdl.CameraID,
    p_camera_ids: ^sdl.CameraID,
    p_camera: ^sdl.Camera,
    count_cameras: i32,         // REVIEW: might need to change this to u32
    selected_index: i32
}

App :: struct {
    event: sdl.Event,
    window: Window,
    camera: Camera,
    p_sdlwindow: ^sdl.Window,
    p_renderer:^sdl.Renderer,
}

init_window :: proc(app: ^App) {
    c_title := strings.clone_to_cstring(app.window.name, context.temp_allocator)
    app.p_sdlwindow = sdl.CreateWindow(
        c_title,
        app.window.w,
        app.window.h,
        app.window.flags
    )

    if app.p_sdlwindow == nil {
        sdl.LogError(i32(sdl.LogCategory.ERROR), "Could not create window: %s", sdl.GetError())
        os.exit(1)
    }
}

init_camera :: proc(app: ^App) {
    app.camera.p_camera_ids = sdl.GetCameras(&app.camera.count_cameras)
    if (app.camera.p_camera_ids == nil) {
        sdl.LogError(i32(sdl.LogCategory.ERROR), "Could not create window: %s", sdl.GetError())
    }
    sdl.Log("number of cameras: %d", app.camera.count_cameras)

    if (app.camera.count_cameras == 0) {
        sdl.LogError(i32(sdl.LogCategory.ERROR), "No Cameras found")
        os.exit(1)
    }

    app.camera.camera_id = ([^]sdl.CameraID)(app.camera.p_camera_ids)[app.camera.selected_index]
    app.camera.p_camera = sdl.OpenCamera(app.camera.camera_id, nil)
    if (app.camera.p_camera == nil) {
        sdl.LogError(i32(sdl.LogCategory.ERROR), "Could not open camera: %s", sdl.GetError())
        os.exit(1)
    }
}

main :: proc() {
    app: App

    app.window.w = 800
    app.window.h = 600
    app.window.flags = sdl.WINDOW_RESIZABLE

    if !sdl.Init(sdl.INIT_CAMERA + sdl.INIT_VIDEO) {
        fmt.println("SDL_Init Error:", sdl.GetError())
        return
    }
    defer sdl.Quit()

    init_window(&app)
    init_camera(&app)

}
