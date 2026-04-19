package main


Entity :: distinct u32
World :: struct {
    next_entity: Entity,
    current_state: States,

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
    boomerangs: ComponentStorage(BoomerangData),
    experience: ComponentStorage(ExperienceData),

    states: map[States]^State,
}

//TODO: hacky just delete the entry of hashmap not the data, should implement 
// some kind of free list for components to reuse data
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
    delete_key(&world.boomerangs.index, entity)
    delete_key(&world.experience.index, entity)
}

create_entity :: proc(world: ^World) -> Entity {
    entity := world.next_entity
    world.next_entity += 1
    return entity
}

change_state :: proc(global: ^GlobalState, new_state: States) {
    global.world.current_state = new_state
    for system in global.world.states[global.world.current_state].init_systems.systems {
        system.update(global)
    }

    if global.world.states[global.world.current_state].initial_run {
        global.world.states[global.world.current_state].initial_run = false
        for system in global.world.states[global.world.current_state].first_system.systems {
            system.update(global)
        }
    }
}

State :: struct {
    initial_run: bool,
    first_system: SystemStorage(System),
    init_systems: SystemStorage(System),
    tick_systems: SystemStorage(TickSystem),
    render_systems: SystemStorage(TickSystem),
}

States :: enum {
    MainMenu,
    Arena,
    ModulePhase,
    Dead,
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

//TODO: hacky just delete the entry of hashmap not the data
remove_component :: proc(storage: ^ComponentStorage($T), entity: Entity) {
    idx, ok := storage.index[entity]
    if !ok || idx < 0 || idx >= len(storage.data) {
        return
    }
    delete_key(&storage.index, entity)
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
