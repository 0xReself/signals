package main

import rl "vendor:raylib"

CardData :: struct {
	label: cstring,
	bg: rl.Color,
    fg: rl.Color,
    flipped: bool,
}

create_card_system :: System {
    proc(global: ^GlobalState) {
        entity := create_entity(&global.world)
        add_component(&global.world.transforms, entity, TransformData{0.0, 0.0})
        add_component(&global.world.render, entity, RenderData{})
        add_component(
            &global.world.cards, 
            entity, 
            CardData{
                "Boomerang", 
                rl.Color{0, 255, 0, 255},
                rl.BLACK,
                false
            }
        )
    }
}

render_card_system :: TickSystem {
    proc(global: ^GlobalState, delta_time: f32) {
        for entity, _ in global.world.cards.index {
            transform := get_component(&global.world.transforms, entity)
            render := get_component(&global.world.render, entity)
            card := get_component(&global.world.cards, entity)

            assert(transform != nil, "Card needs TransformData")
            assert(render != nil, "Card needs Render")

            WIDTH :: 110
            HEIGHT :: 125

            rl.DrawRectangle(
                cast(i32)transform.x, 
                cast(i32)transform.y, 
                WIDTH, 
                HEIGHT, 
                card.bg
            )

            rl.DrawTextEx(
                global.font,
                card.label,
                { transform.x, transform.y },
                18,
                0,
                card.fg
            )
        }
    }
}
