package main

import rl "vendor:raylib"
import "core:slice"
import "core:fmt"
import "core:os"
import "core:strings"
import "core:path/filepath"

SCREEN_WIDTH :: 800
SCREEN_HEIGHT :: 450 

Textures :: map[string]rl.Texture2D

load_textures :: proc(dir: string) -> Textures {
    textures: Textures
    handle, err := os.open(dir)
    if err != nil { return textures }
    defer os.close(handle)

    entries, read_err := os.read_dir(handle, -1, context.allocator)
    if read_err != nil { return textures }

    for entry in entries {
        ext := filepath.ext(entry.name)
        if ext != ".png" { continue }
        name := strings.trim_suffix(entry.name, ext)
        full_path, _ := filepath.join({dir, entry.name}, context.allocator)
        path := strings.clone_to_cstring(full_path)
        textures[name] = rl.LoadTexture(path)
    }
    return textures
}

unload_textures :: proc(textures: ^Textures) {
    for _, tex in textures {
        rl.UnloadTexture(tex)
    }
    delete(textures^)
}

get_texture :: proc(textures: ^Textures, name: string) -> rl.Texture2D {
    if tex, ok := textures[name]; ok {
        return tex
    }
    return {}
}

GlobalState :: struct {
    world: World,
    window: Window,
    font: rl.Font,
    ui: UI,
    debug: DebugState,
    camera: rl.Camera2D,
    textures: Textures,
}

DebugState :: struct {
    draw_colliders: bool,
    show_fps: bool,
}

Window :: struct {
    width: i32,
    height: i32,
}

TransformData :: struct {
    x: f32,
    y: f32,
}

RenderData :: struct {
    _: bool,
}

HealthData :: struct {
    current: i32,
    max: i32,
}

kill_system :: TickSystem {
    proc(global: ^GlobalState, delta_time: f32) {
        for entity, _ in global.world.health.index {
            health := get_component(&global.world.health, entity)
            player := get_component(&global.world.players, entity)
            fmt.println("Checking health...", player)
            if player != nil {
                fmt.println("Player health: ", health.current, "/", health.max)
            }

            if health == nil {
                continue
            }

            if health.current <= 0 {
                if player != nil {
                    change_state(global, .Dead)
                }
                delete_entity(&global.world, entity)
            }
        }
    }
}

debug_colliders_system :: TickSystem {
    proc(global: ^GlobalState, delta_time: f32) {
        if !global.debug.draw_colliders {
            return
        }
        for entity, _ in global.world.circle_colliders.index {
            transform := get_component(&global.world.transforms, entity)
            collider := get_component(&global.world.circle_colliders, entity)

            rl.DrawCircle(
                cast(i32)transform.x, 
                cast(i32)transform.y, 
                collider.radius, 
                rl.Color{0, 255, 0, 20}
            )
        }
    }
}

toggle_debug_system :: TickSystem {
    proc(global: ^GlobalState, delta_time: f32) {
        if rl.IsKeyPressed(.F1) {
            global.debug.draw_colliders = !global.debug.draw_colliders
        }
    }
}

setup_camera_system :: TickSystem {
    proc(global: ^GlobalState, delta_time: f32) {
        global.camera = rl.Camera2D{
            {cast(f32)global.window.width/2, cast(f32)global.window.height/2},
            {cast(f32)SCREEN_WIDTH/2, cast(f32)SCREEN_HEIGHT/2},
            0,
            1,
        }
    }
}

follow_player_system :: TickSystem {
    proc(global: ^GlobalState, delta_time: f32) {
        player_transform: ^TransformData = nil

        for player, _ in global.world.players.index {
            player_transform = get_component(&global.world.transforms, player)
            if player_transform == nil {
                continue
            }

            break
        }

        assert(player_transform != nil, "There must be a player entity with a transform component")

        global.camera.target = rl.Vector2{player_transform.x, player_transform.y}
    }
}

dead_system :: TickSystem {
    proc(global: ^GlobalState, delta_time: f32) {
        rl.DrawTextEx(
            global.font, 
            "You Died", 
            rl.Vector2{cast(f32)global.window.width/2 - 100, cast(f32)global.window.height/2 - 50}, 
            72, 
            0, 
            rl.RED
        )
    }
}

main_menu_render_system :: TickSystem {
    proc(global: ^GlobalState, delta_time: f32) {
        rl.DrawTextEx(
            global.font, 
            "Press Space to Start", 
            rl.Vector2{cast(f32)global.window.width/4 - 200, cast(f32)global.window.height/2 - 50}, 
            72, 
            0, 
            rl.WHITE
        )
    }
}

main_menu_input_system :: TickSystem {
    proc(global: ^GlobalState, delta_time: f32) {
        if rl.IsKeyPressed(.SPACE) {
            change_state(global, .Arena)
        }
    }
}

text_chars: cstring = "@#$%&ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvxyz"

main :: proc() {
    global := GlobalState{}

    global.world.states[.MainMenu] = &State{
        initial_run = true,
        first_system = SystemStorage(System){},
        init_systems = SystemStorage(System){},
        tick_systems = SystemStorage(TickSystem){},
        render_systems = SystemStorage(TickSystem){},
    }

    global.world.states[.Arena] = &State{
        initial_run = true,
        first_system = SystemStorage(System){},
        init_systems = SystemStorage(System){},
        tick_systems = SystemStorage(TickSystem){},
        render_systems = SystemStorage(TickSystem){},
    }

    global.world.states[.ModulePhase] = &State{
        initial_run = true,
        first_system = SystemStorage(System){},
        init_systems = SystemStorage(System){},
        tick_systems = SystemStorage(TickSystem){},
        render_systems = SystemStorage(TickSystem){},
    }

    global.world.states[.Dead] = &State{
        initial_run = true,
        first_system = SystemStorage(System){},
        init_systems = SystemStorage(System){},
        tick_systems = SystemStorage(TickSystem){},
        render_systems = SystemStorage(TickSystem){},
    }


    add_system(&global.world.states[.MainMenu].tick_systems, setup_camera_system)
    add_system(&global.world.states[.Arena].tick_systems, setup_camera_system)
    add_system(&global.world.states[.ModulePhase].tick_systems, setup_camera_system)
    add_system(&global.world.states[.Dead].tick_systems, setup_camera_system)
    add_system(&global.world.states[.Arena].tick_systems, follow_player_system)
   
    add_system(&global.world.states[.MainMenu].tick_systems, main_menu_input_system)
    add_system(&global.world.states[.MainMenu].render_systems, main_menu_render_system)

    add_system(&global.world.states[.Dead].tick_systems, dead_system)

    register_player_systems(&global)
    register_enemy_systems(&global)
    register_collision_systems(&global)
    
    add_system(&global.world.states[.Arena].tick_systems, kill_system)

    add_system(&global.world.states[.Arena].tick_systems, toggle_debug_system)
    add_system(&global.world.states[.Arena].render_systems, debug_colliders_system)

    change_state(&global, .MainMenu)
    rl.SetConfigFlags({.WINDOW_RESIZABLE})
    rl.InitWindow(SCREEN_WIDTH, SCREEN_HEIGHT, "Signals")

    rl.SetTargetFPS(144)
    last_time := rl.GetTime()

    codepoint_count: i32
	codepoints   := rl.LoadCodepoints(text_chars, &codepoint_count)
	deduplicated := codepoints_remove_duplicates(codepoints[:codepoint_count])
	rl.UnloadCodepoints(codepoints)

    font := rl.LoadFontEx("assets/JetBrainsMono-Regular.ttf", 36, raw_data(deduplicated), i32(len(deduplicated)))
    global.font = font
	defer rl.UnloadFont(global.font)
    delete(deduplicated)

    rl.SetTextureFilter(global.font.texture, .BILINEAR)
    rl.SetTextLineSpacing(72)

    global.textures = load_textures("assets/img")
    defer unload_textures(&global.textures)

    for !rl.WindowShouldClose() {
        current_time := rl.GetTime()
        delta_time := cast(f32)(current_time - last_time)
        last_time = current_time

        global.window.width = rl.GetScreenWidth()
        global.window.height = rl.GetScreenHeight()

        if rl.IsKeyDown(.ESCAPE) {
            break;
        }
        for system in global.world.states[global.world.current_state].tick_systems.systems {
            system.update(&global, delta_time)
        }

        rl.BeginDrawing()
        rl.ClearBackground(rl.BLACK)
        
        rl.BeginMode2D(global.camera)
        for system in global.world.states[global.world.current_state].render_systems.systems {
            system.update(&global, delta_time)
        }
        rl.EndMode2D()
        
        if global.world.current_state == .Arena {
            begin_frame(&global.ui)
            tree := ui_tree(&global)
            compute_layout(tree, global.font, cast(f32)global.window.width, cast(f32)global.window.height)
            process_interactions(&global.ui, tree)
            end_frame(&global.ui)
            draw_ui(&global, tree)
        }
        rl.EndDrawing()
    }

    rl.CloseWindow()
}

codepoints_remove_duplicates :: proc (codepoints: []rune) -> (deduplicated: []rune) {
	deduplicated = slice.clone(codepoints)
	slice.sort(deduplicated)
	return slice.unique(deduplicated)
}
