package main

import "core:fmt"
import "core:strings"
import "core:time"
import "core:os"
import "core:slice"
import sdl "vendor:sdl3"

Window :: struct {
    name: string,
    x: i32,
    y: i32,
    w: i32,
    h: i32,
    flags: sdl.WindowFlags,
}

Camera :: struct {
    camera_ids: []sdl.CameraID,
    p_camera: ^sdl.Camera,
    selected_index: int
}

Window_Reset_Mode :: enum {
    None,
    Larget_Side,
    Smaller_Side,
}

Snapshot_Requested :: enum {
    None,
    Fullsize,
    Screensize,
}

Render_Mode :: enum {
    Standard,
    Ascii,
}

App :: struct {
    p_sdlwindow: ^sdl.Window,
    p_renderer: ^sdl.Renderer,
    p_texture: sdl.Texture,
    p_ascii_texture: sdl.Texture,
    event: sdl.Event,
    window: Window,
    cameras: Camera,

    render_mode: Render_Mode,
    window_reset_mode: Window_Reset_Mode,
    snapshot_requested: Snapshot_Requested,

    quit: bool,
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
    // app.camera.p_camera_ids = sdl.GetCameras(&app.camera.count_cameras)

    count: i32
    p_camera_ids := sdl.GetCameras(&count)

    if p_camera_ids != nil && count > 0 {
        app.cameras.camera_ids = slice.from_ptr(p_camera_ids, int(count))
        sdl.Log("number of cameras: %d", count)
    } else {
        sdl.LogError(i32(sdl.LogCategory.ERROR), "Could not find cameras: %s", sdl.GetError())
        os.exit(1)
    }

    app.cameras.selected_index = 0
    app.cameras.p_camera = sdl.OpenCamera(p_camera_ids[app.cameras.selected_index], nil)
    if (app.cameras.p_camera == nil) {
        sdl.LogError(i32(sdl.LogCategory.ERROR), "Could not open camera: %s", sdl.GetError())
        os.exit(1)
    }
}

clear_render_to_dark_grey :: proc(app: ^App) {
    sdl.SetRenderDrawColor(app.p_renderer, 18, 18, 18, 0)
    sdl.RenderClear(app.p_renderer)
}

init_camera_renderer :: proc(app: ^App) {
    app.p_renderer = sdl.CreateRenderer(app.p_sdlwindow, nil)
    clear_render_to_dark_grey(app)
    sdl.RenderPresent(app.p_renderer)
}

camera_render_loop :: proc(app: ^App) {
    for app.quit != true {
        for sdl.PollEvent(&app.event) != false {
            //handle_event(app)
        }

        // Clear every frame
        clear_render_to_dark_grey(app)

        timestamp_ns: u64
        p_cam_surface: ^sdl.Surface = sdl.AcquireCameraFrame(app.cameras.p_camera, &timestamp_ns)

        // TODO: Update textures
        // TODO: Render textures
        sdl.RenderPresent(app.p_renderer)

        // Sleep targeting 60 FPS
        duration := 16667 * time.Microsecond
        time.sleep(duration)

    }
}

main :: proc() {
    app: App

    app.window.w = 800
    app.window.h = 600
    app.window.flags = sdl.WINDOW_RESIZABLE
    app.quit = false
    app.render_mode = Render_Mode.Standard
    app.window_reset_mode = Window_Reset_Mode.None
    app.snapshot_requested = Snapshot_Requested.None

    if !sdl.Init(sdl.INIT_CAMERA + sdl.INIT_VIDEO) {
        fmt.println("SDL_Init Error:", sdl.GetError())
        return
    }
    defer sdl.Quit()

    init_window(&app)
    init_camera(&app)
    init_camera_renderer(&app)
    camera_render_loop(&app)

}
