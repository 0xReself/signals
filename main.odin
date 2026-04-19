package main

import rl "vendor:raylib"

GlobalState :: struct {
    screen_width: u32,
    screen_height: u32,
    world: World 
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

create_player :: System {
    proc(global: ^GlobalState) {
        entity := create_entity(&global.world)
        add_component(&global.world.transforms, entity, 
            TransformData{cast(f32)global.screen_width/2, cast(f32)global.screen_height/2})
        add_component(&global.world.players, entity, PlayerData{})
        add_component(&global.world.render, entity, RenderData{rl.BLUE})
    }
}

player_render_system :: System {
    proc(global: ^GlobalState) {
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

player_movement_system :: System {
    proc(global: ^GlobalState) {
        for entity, _ in global.world.players.index {
            transform := get_component(&global.world.transforms, entity)
            assert(transform != nil, "Player entity must have a transform component")

            if rl.IsKeyDown(.D) {
                transform.x += 5 
            }
            if rl.IsKeyDown(.A) {
                transform.x -= 5
            }
            if rl.IsKeyDown(.W) {
                transform.y -= 5
            }
            if rl.IsKeyDown(.S) {
                transform.y += 5
            }
        }
    }
}
SCREEN_WIDTH :: 800
SCREEN_HEIGHT :: 450

main :: proc() {
    global := GlobalState{
        SCREEN_WIDTH,
        SCREEN_HEIGHT,
        World{},
    }
    add_system(&global.world.init_systems, create_player)
    add_system(&global.world.tick_systems, player_movement_system)
    add_system(&global.world.render_systems, player_render_system)

    rl.InitWindow(SCREEN_WIDTH, SCREEN_HEIGHT, "Signals")

    for system in global.world.init_systems.systems {
        system.update(&global)
    }
    rl.SetTargetFPS(144)

    for !rl.WindowShouldClose() {
        if rl.IsKeyDown(.ESCAPE) {
            break;
        }
        for system in global.world.tick_systems.systems {
            system.update(&global)
        }

        rl.BeginDrawing()
        rl.ClearBackground(rl.BLACK)
        for system in global.world.render_systems.systems {
            system.update(&global)
        }
        rl.EndDrawing()
    }

    rl.CloseWindow()
}
