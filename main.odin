package main

import rl "vendor:raylib"
import "core:slice"
import "core:fmt"

SCREEN_WIDTH :: 800
SCREEN_HEIGHT :: 450 

GlobalState :: struct {
    world: World,
    window: Window,
    font: rl.Font,
    ui: UI,
    debug: DebugState,
    Camera: rl.Camera2D,
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
        global.Camera = rl.Camera2D{
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

        global.Camera.target = rl.Vector2{player_transform.x, player_transform.y}
    }
}

text_chars: cstring = "@#$%&ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvxyz"

main :: proc() {
    global := GlobalState{}
    add_system(&global.world.tick_systems, setup_camera_system)
    add_system(&global.world.tick_systems, follow_player_system)

    register_player_systems(&global)
    register_enemy_systems(&global)
    register_collision_systems(&global)
    
    add_system(&global.world.tick_systems, kill_system)

    add_system(&global.world.tick_systems, toggle_debug_system)
    add_system(&global.world.render_systems, debug_colliders_system)

    rl.SetConfigFlags({.WINDOW_RESIZABLE})
    rl.InitWindow(SCREEN_WIDTH, SCREEN_HEIGHT, "Signals")

    for system in global.world.init_systems.systems {
        system.update(&global)
    }
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

    for !rl.WindowShouldClose() {
        current_time := rl.GetTime()
        delta_time := cast(f32)(current_time - last_time)
        last_time = current_time

        global.window.width = rl.GetScreenWidth()
        global.window.height = rl.GetScreenHeight()

        if rl.IsKeyDown(.ESCAPE) {
            break;
        }
        for system in global.world.tick_systems.systems {
            system.update(&global, delta_time)
        }

        rl.BeginDrawing()
        rl.ClearBackground(rl.BLACK)
        
        rl.BeginMode2D(global.Camera)
        for system in global.world.render_systems.systems {
            system.update(&global, delta_time)
        }
        rl.EndMode2D()

        begin_frame(&global.ui)
        tree := ui_tree(&global.ui)
        compute_layout(tree, global.font, cast(f32)global.window.width, cast(f32)global.window.height)
        process_interactions(&global.ui, tree)
        end_frame(&global.ui)
        draw_ui(&global, tree)

        rl.EndDrawing()
    }

    rl.CloseWindow()
}

codepoints_remove_duplicates :: proc (codepoints: []rune) -> (deduplicated: []rune) {
	deduplicated = slice.clone(codepoints)
	slice.sort(deduplicated)
	return slice.unique(deduplicated)
}
