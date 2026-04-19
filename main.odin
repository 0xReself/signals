package main

import rl "vendor:raylib"
import "core:slice"

SCREEN_WIDTH :: 800
SCREEN_HEIGHT :: 450 

GlobalState :: struct {
    world: World,
    window: Window,
    font: rl.Font
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

ENEMY_LABELS :: [5]cstring {"@", "#", "$", "%", "&"}
EnemyData :: struct {
    label: cstring,
    speed: f32,
}
RenderData :: struct {
    _: bool, // Just to have some data in render component for now
}

CircleCollider :: struct {
    radius: f32
}

EnemySpawnerData :: struct {
    timer: f32,
    interval: f32, // how much seconds to spawn enemy
}

create_enemy_spawner_system :: System {
    proc(global: ^GlobalState) {
        entity := create_entity(&global.world)
        add_component(&global.world.enemy_spawners, entity, EnemySpawnerData{0, 2})
    }
}

spawn_enemy_system :: TickSystem {
    proc(global: ^GlobalState, delta_time: f32) {
        for entity, _ in global.world.enemy_spawners.index {
            spawner := get_component(&global.world.enemy_spawners, entity)
            if spawner == nil {
                continue
            }

            spawner.timer += delta_time
            if spawner.timer >= spawner.interval {
                spawner.timer = 0

                enemy_entity := create_entity(&global.world)

                //Get somewhat random position on screen
                width := rl.GetRandomValue(0, global.window.height)
                height := rl.GetRandomValue(0, global.window.height)
                add_component(&global.world.transforms, enemy_entity, 
                    TransformData{cast(f32)width, cast(f32)height})

                //Get random label for enemy
                label_index := rl.GetRandomValue(0, len(ENEMY_LABELS)-1)
                labels := ENEMY_LABELS
                add_component(&global.world.enemies, 
                    enemy_entity, 
                    EnemyData{labels[label_index], 50}
                )
                add_component(&global.world.render, enemy_entity, RenderData{})
            }
        }
    }
}

render_enemy_system :: TickSystem {
    proc(global: ^GlobalState, delta_time: f32) {
        for entity, _ in global.world.enemies.index {
            transform := get_component(&global.world.transforms, entity)
            render := get_component(&global.world.render, entity)
            enemy := get_component(&global.world.enemies, entity)

            assert(transform != nil, "Enemy entity must have a transform component")
            assert(render != nil, "Enemy entity must have a render component")

            rl.DrawTextEx(
                global.font,
                enemy.label,
                { transform.x, transform.y },
                36,
                0,
                rl.Color{255, 255, 255, 127}
            )
        }
    }
}

enemy_movement_system :: TickSystem {
    proc(global: ^GlobalState, delta_time: f32) {
        for entity, _ in global.world.enemies.index {
            transform := get_component(&global.world.transforms, entity)
            assert(transform != nil, "Enemy entity must have a transform component")
            enemy := get_component(&global.world.enemies, entity)

            player_transform: ^TransformData = nil

            for player, _ in global.world.players.index {
                player_transform = get_component(&global.world.transforms, player)
                if player_transform == nil {
                    continue
                }

                break
            }

            assert(player_transform != nil, "There must be a player entity with a transform component")
            
            current_position := rl.Vector2{transform.x, transform.y}
            player_position := rl.Vector2{player_transform.x, player_transform.y}
            direction := player_position - current_position
            normalized_direction := rl.Vector2Normalize(direction)
            
            transform.x += normalized_direction.x * enemy.speed * delta_time
            transform.y += normalized_direction.y * enemy.speed * delta_time
        }
    }
}

create_player_system :: System {
    proc(global: ^GlobalState) {
        entity := create_entity(&global.world)
        add_component(&global.world.transforms, entity, 
            TransformData{cast(f32)SCREEN_WIDTH/2, cast(f32)SCREEN_HEIGHT/2})
        add_component(&global.world.players, entity, PlayerData{})
        add_component(&global.world.render, entity, RenderData{})
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
                rl.WHITE
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


text: cstring = "@#$%&ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvxyz"

main :: proc() {
    global := GlobalState{}
    add_system(&global.world.init_systems, create_player_system)
    add_system(&global.world.tick_systems, player_movement_system)
    add_system(&global.world.render_systems, player_render_system)
    
    add_system(&global.world.init_systems, create_enemy_spawner_system)
    add_system(&global.world.tick_systems, spawn_enemy_system)
    add_system(&global.world.tick_systems, enemy_movement_system)
    add_system(&global.world.render_systems, render_enemy_system)

    add_system(&global.world.init_systems, create_card_system)
    add_system(&global.world.ui_systems, render_card_system)

    rl.SetConfigFlags({.WINDOW_RESIZABLE})
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

codepoints_remove_duplicates :: proc (codepoints: []rune) -> (deduplicated: []rune) {
	deduplicated = slice.clone(codepoints)
	slice.sort(deduplicated)
	return slice.unique(deduplicated)
}
