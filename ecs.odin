package main

Entity :: distinct u32
World :: struct {
    next_entity: Entity,

    transforms: ComponentStorage(TransformData),
    players: ComponentStorage(PlayerData),
    enemies: ComponentStorage(EnemyData),
    render: ComponentStorage(RenderData),

    init_systems: SystemStorage(System),
    tick_systems: SystemStorage(TickSystem),
    render_systems: SystemStorage(TickSystem),
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
    if !ok {
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
