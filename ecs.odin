package main

Entity :: distinct u32
World :: struct {
    next_entity: Entity,

    transforms: ComponentStorage(TransformData),
    players: ComponentStorage(PlayerData),
    enemies: ComponentStorage(EnemyData),
    render: ComponentStorage(RenderData),
    cards: ComponentStorage(CardData),
    enemy_spawners: ComponentStorage(EnemySpawnerData),
    circle_colliders: ComponentStorage(CircleCollider),
    circle_hitboxes: ComponentStorage(CircleHitbox),
    health: ComponentStorage(HealthData),
    momentum: ComponentStorage(MomentumData),

    init_systems: SystemStorage(System),
    tick_systems: SystemStorage(TickSystem),
    render_systems: SystemStorage(TickSystem),
    ui_systems: SystemStorage(TickSystem),
}

delete_entity :: proc(world: ^World, entity: Entity) {
    delete_key(&world.transforms.index, entity)
    delete_key(&world.players.index, entity)
    delete_key(&world.enemies.index, entity)
    delete_key(&world.render.index, entity)
    delete_key(&world.cards.index, entity)
    delete_key(&world.enemy_spawners.index, entity)
    delete_key(&world.circle_colliders.index, entity)
    delete_key(&world.circle_hitboxes.index, entity)
    delete_key(&world.health.index, entity)
    delete_key(&world.momentum.index, entity)
}

create_entity :: proc(world: ^World) -> Entity {
    entity := world.next_entity
    world.next_entity += 1
    return entity
}


ComponentStorage :: struct($T: typeid) {
    data: [dynamic]T,
    index: map[Entity]int
}

add_component :: proc(storage: ^ComponentStorage($T), entity: Entity, data: T) {
    idx := len(storage.data)
    append(&storage.data, data)
    map_insert(&storage.index, entity, idx)
}

get_component :: proc(storage: ^ComponentStorage($T), entity: Entity) -> ^T {
    idx, ok := storage.index[entity]
    if !ok || idx < 0 || idx >= len(storage.data) {
        return nil
    }
    return &storage.data[idx]
}

System :: struct {
    update: proc(global: ^GlobalState)
}

TickSystem :: struct {
    update: proc(global: ^GlobalState, delta_time: f32)
}

SystemStorage :: struct($T: typeid) {
    systems: [dynamic]T,
}

add_system :: proc(storage: ^SystemStorage($T), system: T) {
    append(&storage.systems, system)
}
