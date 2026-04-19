package main

import rl "vendor:raylib"
import "core:fmt"
import "core:math"

BoomerangData :: struct {
    flight_away: bool, 
    target: Maybe(rl.Vector2),
    throw_distance: f32,
    speed: f32,
    hit_enemies: [dynamic]Entity,
}

boomerang_action_system :: TickSystem {
    proc(global: ^GlobalState, delta_time: f32) {
        for entity, _ in global.world.boomerangs.index {
            transform := get_component(&global.world.transforms, entity)
            boomerang := get_component(&global.world.boomerangs, entity)
            
            // Clear hit enemies when starting a new flight away from player
            if boomerang.flight_away && boomerang.target == nil {
                boomerang.hit_enemies = nil
            }
            
            player_transform: ^TransformData = nil
            for player_entity, _ in global.world.players.index {
                player_transform = get_component(&global.world.transforms, player_entity)
            }
            
            fmt.println("Boomerang position: ", transform, " Boomerang target: ", boomerang.target)
            
            if boomerang.flight_away == true {
                // Flight away from player toward target
                if boomerang.target == nil {
                    // Find closest enemy
                    closest_enemy: Maybe(rl.Vector2) = nil 
                    closest_distance: f32 = 999999999.0 
                    for enemy_entity, _ in global.world.enemies.index {
                        enemy_transform := get_component(&global.world.transforms, enemy_entity)
                        if enemy_transform == nil {
                            continue
                        }
                        distance := rl.Vector2Distance(
                                      rl.Vector2{enemy_transform.x, enemy_transform.y}, 
                                      rl.Vector2{transform.x, transform.y}
                                  ) 
                        if distance < closest_distance {
                            closest_enemy = rl.Vector2{enemy_transform.x, enemy_transform.y}
                            closest_distance = distance
                        }
                    }

                    if closest_enemy == nil {
                        // Choose random unit vector direction if there is no enemy
                        angle := cast(f32)(rl.GetRandomValue(0, 360)) * math.PI / 180.0
                        random_dir := rl.Vector2{math.cos(angle), math.sin(angle)}
                        boomerang.target = rl.Vector2{
                            player_transform.x + random_dir.x * boomerang.throw_distance,
                            player_transform.y + random_dir.y * boomerang.throw_distance,
                        }
                    } else {
                        // Set target to the enemy position
                        boomerang.target = closest_enemy.(rl.Vector2)
                    }
                }

                // Compute direction to target
                target_pos := boomerang.target.(rl.Vector2)
                direction := rl.Vector2{
                    target_pos.x - transform.x,
                    target_pos.y - transform.y,
                }
                distance := rl.Vector2Length(direction)
                
                if distance < 2.0 {
                    boomerang.flight_away = false
                    boomerang.target = nil  // Clear target for next throw
                    continue
                }

                step := boomerang.speed * delta_time
                if step >= distance {
                    transform.x = target_pos.x
                    transform.y = target_pos.y
                    boomerang.flight_away = false
                    boomerang.target = nil
                    continue
                }

                direction = rl.Vector2Normalize(direction)
                transform.x += step * direction.x
                transform.y += step * direction.y
            } else {
                // Returning to player
                direction := rl.Vector2{
                    player_transform.x - transform.x,
                    player_transform.y - transform.y,
                }
                distance := rl.Vector2Length(direction)
                
                if distance < 1.0 {
                    boomerang.flight_away = true
                    boomerang.target = nil  // Clear target for next throw
                    continue
                }

                step := boomerang.speed * delta_time
                if step >= distance {
                    transform.x = player_transform.x
                    transform.y = player_transform.y
                    boomerang.flight_away = true
                    boomerang.target = nil
                    continue
                }

                direction = rl.Vector2Normalize(direction)
                transform.x += step * direction.x
                transform.y += step * direction.y
            }
        }
    }
}

boomerang_register_hits :: TickSystem {
    proc(global: ^GlobalState, delta_time: f32) {
        for entity, _ in global.world.boomerangs.index {
            transform := get_component(&global.world.transforms, entity)
            boomerang := get_component(&global.world.boomerangs, entity)

            for enemy_entity, _ in global.world.enemies.index {
                enemy_transform := get_component(&global.world.transforms, enemy_entity)
                if enemy_transform == nil {
                    continue
                }

                distance := rl.Vector2Distance(
                    rl.Vector2{enemy_transform.x, enemy_transform.y}, 
                    rl.Vector2{transform.x, transform.y}
                )

                if distance < 12.5 + 10.0 { // Enemy hitbox radius + Boomerang hitbox radius
                    // Check if enemy already hit this flight
                    already_hit := false
                    for hit_entity in boomerang.hit_enemies {
                        if hit_entity == enemy_entity {
                            already_hit = true
                            break
                        }
                    }
                    if already_hit {
                        continue
                    }
                    // Add to hit list
                    append(&boomerang.hit_enemies, enemy_entity)
                    
                    health := get_component(&global.world.health, enemy_entity)
                    if health != nil {
                        health.current -= 10
                    }
                }
            }
        }
    }
}

render_boomerang_system :: TickSystem {
    proc(global: ^GlobalState, delta_time: f32) {
        for entity, _ in global.world.boomerangs.index {
            transform := get_component(&global.world.transforms, entity)
            render := get_component(&global.world.render, entity)
            
            assert(transform != nil, "Boomerang entity must have a transform component")
            if render == nil {
                continue
            }

            rl.DrawCircleV(
                rl.Vector2{transform.x, transform.y}, 
                10.0, 
                rl.YELLOW
            )
        }
    }
}

register_weapon_systems :: proc(global: ^GlobalState) {
    append(&global.world.states[.Arena].tick_systems.systems, boomerang_action_system)
    append(&global.world.states[.Arena].tick_systems.systems, boomerang_register_hits)
    append(&global.world.states[.Arena].render_systems.systems, render_boomerang_system)
}
