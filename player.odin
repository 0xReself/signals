package main

import rl "vendor:raylib"
import "core:fmt"

PlayerData :: struct {
    _: bool, // Just to have some data in player component for now
}

player_damage_system :: TickSystem {
    proc(global: ^GlobalState, delta_time: f32) {
        for entity, _ in global.world.players.index {
            health := get_component(&global.world.health, entity)
            transform := get_component(&global.world.transforms, entity)
            circle_hitboxe := get_component(&global.world.circle_hitboxes, entity)

            for enemy_entity, _ in global.world.enemies.index {
                enemy_transform := get_component(&global.world.transforms, enemy_entity)
                enemy_collider := get_component(&global.world.circle_colliders, enemy_entity)
                
                max_distance := enemy_collider.radius + circle_hitboxe.radius

                distance := rl.Vector2Distance(
                    rl.Vector2{enemy_transform.x, enemy_transform.y}, 
                    rl.Vector2{transform.x, transform.y}
                )

                if distance < max_distance {
                    overlap := max_distance - distance
                    direction := rl.Vector2Normalize(
                            rl.Vector2{transform.x, transform.y} -  
                            rl.Vector2{enemy_transform.x, enemy_transform.y}
                    )
                    damage_push: f32 = 100.0
                    add_component(
                        &global.world.momentum, 
                        entity, 
                        MomentumData {
                            direction.x * damage_push, 
                            direction.y * damage_push
                        }
                    )
                    add_component(
                        &global.world.momentum, 
                        enemy_entity, 
                        MomentumData {
                            -direction.x * damage_push, 
                            -direction.y * damage_push
                        }
                    )

                    if health == nil {
                        continue
                    }

                    health.current -= 10
                }
            }
        }
    }
}

collect_experience_system :: TickSystem {
    proc(global: ^GlobalState, delta_time: f32) {
        fmt.println("Collecting experience...", global.experience)
        for player_entity, _ in global.world.players.index {
            player_transform := get_component(&global.world.transforms, player_entity)
            player_hitbox := get_component(&global.world.circle_hitboxes, player_entity)

            for exp_entity, _ in global.world.experience.index {
                exp_transform := get_component(&global.world.transforms, exp_entity)
                exp := get_component(&global.world.experience, exp_entity)

                distance := rl.Vector2Distance(
                    rl.Vector2{player_transform.x, player_transform.y}, 
                    rl.Vector2{exp_transform.x, exp_transform.y}
                )

                if distance < player_hitbox.radius * 5 {
                    global.experience += exp.amount 
                    delete_entity(&global.world, exp_entity)
                }
            }
        }
    }
}

create_player_system :: System {
    proc(global: ^GlobalState) {
        entity := create_entity(&global.world)
        add_component(&global.world.transforms, entity, 
            TransformData{0.0, 0.0})
        add_component(&global.world.players, entity, PlayerData{})
        add_component(&global.world.render, entity, RenderData{})
        add_component(&global.world.health, entity, HealthData{100, 100})
        add_component(&global.world.circle_hitboxes, entity, CircleHitbox{12.5})

        boomerang := create_entity(&global.world)
        add_component(&global.world.transforms, boomerang, 
            TransformData{0.0, 0.0})
        add_component(&global.world.boomerangs, boomerang, BoomerangData{
            flight_away = false,
            target = nil,
            throw_distance = 300.0,
            speed = 400.0,
            hit_enemies = nil,
        })
        add_component(&global.world.render, boomerang, RenderData{})
        add_component(&global.world.circle_hitboxes, boomerang, CircleHitbox{10.0})
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
                rl.Vector2{transform.x - 12.5, transform.y - 12.5}, 
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

register_player_systems :: proc(global: ^GlobalState) {
    add_system(&global.world.states[.Arena].first_system, create_player_system)
    add_system(&global.world.states[.Arena].tick_systems, player_movement_system)
    add_system(&global.world.states[.Arena].tick_systems, player_damage_system)
    add_system(&global.world.states[.Arena].render_systems, player_render_system)
    add_system(&global.world.states[.Arena].tick_systems, collect_experience_system)
}
