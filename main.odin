package main

import rl "vendor:raylib"

SCREEN_WIDTH :: 800
SCREEN_HEIGHT :: 450

GlobalState :: struct {
    window: Window,
    world: World 
}

Window :: struct {
    width: i32,
    height: i32,
}

TransformData :: struct {
    x: f32,
    y: f32,
}

PlayerData :: struct {}
EnemyData :: struct {}
RenderData :: struct {
    color: rl.Color
}


create_player_system :: System {
    proc(global: ^GlobalState) {
        entity := create_entity(&global.world)
        add_component(&global.world.transforms, entity, 
            TransformData{cast(f32)SCREEN_WIDTH/2, cast(f32)SCREEN_HEIGHT/2})
        add_component(&global.world.players, entity, PlayerData{})
        add_component(&global.world.render, entity, RenderData{rl.BLUE})
    }
}

player_render_system :: TickSystem {
    proc(global: ^GlobalState, delta_time: f32) {
        for entity, _ in global.world.players.index {
            transform := get_component(&global.world.transforms, entity)
            render := get_component(&global.world.render, entity)

            assert(transform != nil, "Player entity must have a transform component")
            assert(render != nil, "Player entity must have a render component")

            rl.DrawRectangleV(
                rl.Vector2{transform.x, transform.y}, 
                rl.Vector2{25, 25}, 
                render.color
            )
        }
    }
}

player_movement_system :: TickSystem {
    proc(global: ^GlobalState, detla_time: f32) {
        for entity, _ in global.world.players.index {
            transform := get_component(&global.world.transforms, entity)
            assert(transform != nil, "Player entity must have a transform component")

            if rl.IsKeyDown(.D) {
                transform.x += 100 * detla_time 
            }
            if rl.IsKeyDown(.A) {
                transform.x -= 100 * detla_time
            }
            if rl.IsKeyDown(.W) {
                transform.y -= 100 * detla_time
            }
            if rl.IsKeyDown(.S) {
                transform.y += 100 * detla_time
            }
        }
    }
}

main :: proc() {
    global := GlobalState{}
    add_system(&global.world.init_systems, create_player_system)
    add_system(&global.world.tick_systems, player_movement_system)
    add_system(&global.world.render_systems, player_render_system)

    rl.SetConfigFlags({.WINDOW_RESIZABLE})
    rl.InitWindow(SCREEN_WIDTH, SCREEN_HEIGHT, "Signals")

    for system in global.world.init_systems.systems {
        system.update(&global)
    }
    rl.SetTargetFPS(144)
    last_time := rl.GetTime()
    for !rl.WindowShouldClose() {
        current_time := rl.GetTime()
        delta_time := cast(f32)(current_time - last_time)
        last_time = current_time

        //Get Current window dimensions for global state
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

        for system in global.world.render_systems.systems {
            system.update(&global, delta_time)
        }

        for system in global.world.ui_systems.systems {
            system.update(&global, delta_time)
        }
        rl.EndDrawing()
    }

    rl.CloseWindow()
}
