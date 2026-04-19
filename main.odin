package main

import "core:fmt"
import rl "vendor:raylib"
import "core:slice"

GlobalState :: struct {
    screen_width: u32,
    screen_height: u32,
    world: World,
    font: rl.Font
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
SCREEN_WIDTH :: 800
SCREEN_HEIGHT :: 450


text: cstring = "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvxyz"

main :: proc() {
    global := GlobalState{
        SCREEN_WIDTH,
        SCREEN_HEIGHT,
        World{},
    }
    add_system(&global.world.init_systems, create_player)
    add_system(&global.world.tick_systems, player_movement_system)
    add_system(&global.world.render_systems, player_render_system)

    add_system(&global.world.init_systems, create_card_system)
    add_system(&global.world.ui_systems, render_card_system)


    rl.InitWindow(SCREEN_WIDTH, SCREEN_HEIGHT, "Signals")

    for system in global.world.init_systems.systems {
        system.update(&global)
    }
    rl.SetTargetFPS(144)
    last_time := rl.GetTime()


    // Font loading
    codepoint_count: i32
	codepoints   := rl.LoadCodepoints(text, &codepoint_count)
	deduplicated := codepoints_remove_duplicates(codepoints[:codepoint_count])
	rl.UnloadCodepoints(codepoints)

    global.font := rl.LoadFontEx("assets/JetBrainsMono-Regular.ttf", 36, raw_data(deduplicated), i32(len(deduplicated)))
	defer rl.UnloadFont(global.font)
    delete(deduplicated)

    rl.SetTextureFilter(font.texture, .BILINEAR)
    rl.SetTextLineSpacing(72)

    for !rl.WindowShouldClose() {
        current_time := rl.GetTime()
        delta_time := cast(f32)(current_time - last_time)
        last_time = current_time

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

codepoints_remove_duplicates :: proc (codepoints: []rune) -> (deduplicated: []rune) {
	deduplicated = slice.clone(codepoints)
	slice.sort(deduplicated)
	return slice.unique(deduplicated)
}
