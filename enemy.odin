package main

import rl "vendor:raylib"

EnemySpawnerData :: struct {
    timer: f32,
    interval: f32, // how much seconds to spawn enemy
}

ENEMY_LABELS :: [5]cstring {"@", "#", "$", "%", "&"}
EnemyData :: struct {
    label: cstring,
    speed: f32,
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
                add_component(&global.world.circle_colliders, enemy_entity, CircleCollider{12.5})
                add_component(&global.world.health, enemy_entity, HealthData{10, 10})
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
                { transform.x - 9, transform.y - 18 },
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

register_enemy_systems :: proc(global: ^GlobalState) {
    add_system(&global.world.states[.Arena].first_system, create_enemy_spawner_system)
    add_system(&global.world.states[.Arena].tick_systems, spawn_enemy_system)
    add_system(&global.world.states[.Arena].tick_systems, enemy_movement_system)
    add_system(&global.world.states[.Arena].render_systems, render_enemy_system)
}
