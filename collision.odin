package main

import rl "vendor:raylib"

MomentumData :: struct {
    x: f32,
    y: f32,
}

CircleCollider :: struct {
    radius: f32
}

CircleHitbox :: struct {
    radius: f32,
}

resolve_collision_system :: TickSystem {
    proc(global: ^GlobalState, delta_time: f32) {
        for entity, _ in global.world.circle_colliders.index {
            transform := get_component(&global.world.transforms, entity)
            collider := get_component(&global.world.circle_colliders, entity)

            for entity2, _ in global.world.circle_colliders.index {
                if entity == entity2 {
                    continue
                }
                transform2 := get_component(&global.world.transforms, entity2)
                collider2 := get_component(&global.world.circle_colliders, entity2)

                distance := rl.Vector2Distance(
                    rl.Vector2{transform.x, transform.y}, 
                    rl.Vector2{transform2.x, transform2.y}
                )

                max_distance := collider.radius + collider2.radius
                    //collider.radius > collider2.radius ? collider.radius : collider2.radius 

                if distance < max_distance {
                    overlap := max_distance - distance
                    direction := rl.Vector2Normalize(
                            rl.Vector2{transform.x, transform.y} -  
                            rl.Vector2{transform2.x, transform2.y}
                    )
                    transform.x += direction.x * overlap * 0.5
                    transform.y += direction.y * overlap * 0.5
                    transform2.x -= direction.x * overlap * 0.5
                    transform2.y -= direction.y * overlap * 0.5
                }
            }
        }
    }
}

decay_momentum_system :: TickSystem {
    proc(global: ^GlobalState, delta_time: f32) {
        for entity, _ in global.world.momentum.index {
            momentum := get_component(&global.world.momentum, entity)
            transform := get_component(&global.world.transforms, entity)

            if momentum == nil || transform == nil {
                continue
            }
            
            transform.x += momentum.x * delta_time
            transform.y += momentum.y * delta_time
            momentum.x *= 0.99 
            momentum.y *= 0.99
            if abs(momentum.x) < 0.01 && abs(momentum.y) < 0.01 {
                remove_component(&global.world.momentum, entity)
            }
        }
    }
}

register_collision_systems :: proc(global: ^GlobalState) {
    add_system(&global.world.tick_systems, resolve_collision_system)
    add_system(&global.world.tick_systems, decay_momentum_system)
}
