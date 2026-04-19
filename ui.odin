package main

import rl "vendor:raylib"

SlotPositions :: enum i32 {
    TOP_LEFT,
    TOP_RIGHT,
    BOTTOM_LEFT,
    BOTTOM_RIGHT,
}

CardData :: struct {
	label: cstring,
	bg: rl.Color,
    fg: rl.Color,
    flipped: bool,
    slots: bit_set[SlotPositions; i32]
}

create_card_system :: System {
    proc(global: ^GlobalState) {
        entity := create_entity(&global.world)
        add_component(&global.world.transforms, entity, TransformData{10.0, 10.0})
        add_component(&global.world.render, entity, RenderData{})
        add_component(
            &global.world.cards, 
            entity, 
            CardData{
                "Boomerang", 
                rl.Color{0, 255, 0, 255},
                rl.BLACK,
                false,
                {.TOP_LEFT, .TOP_RIGHT, .BOTTOM_LEFT, .BOTTOM_RIGHT}
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
            TEXT_SIZE :: 18

            SLOT_OFFSET :: 8
            SLOT_SIZE :: 11
            SLOT_COLOR :: rl.GRAY 

            // Card Outline
            draw_rectangle_border({transform.x, transform.y}, WIDTH, HEIGHT, card.bg, 1)

            // Label
            rl.DrawRectangle(cast(i32)transform.x, cast(i32)transform.y, WIDTH, TEXT_SIZE, card.bg)
            rl.DrawTextEx(global.font, card.label, { transform.x, transform.y }, TEXT_SIZE, 0, card.fg)

            if .TOP_LEFT in card.slots {
                draw_rectangle_border({transform.x + SLOT_OFFSET, transform.y + SLOT_OFFSET + TEXT_SIZE}, SLOT_SIZE, SLOT_SIZE, SLOT_COLOR, 2)
            }

            if .TOP_RIGHT in card.slots {
                draw_rectangle_border({transform.x + WIDTH - SLOT_SIZE - SLOT_OFFSET, transform.y + SLOT_OFFSET + TEXT_SIZE}, SLOT_SIZE, SLOT_SIZE, SLOT_COLOR, 2)
            }

            if .BOTTOM_LEFT in card.slots {
                draw_rectangle_border({transform.x + SLOT_OFFSET, transform.y + HEIGHT - SLOT_SIZE - SLOT_OFFSET}, SLOT_SIZE, SLOT_SIZE, SLOT_COLOR, 2)
            }

            if .BOTTOM_RIGHT in card.slots {
                draw_rectangle_border({transform.x + WIDTH - SLOT_SIZE - SLOT_OFFSET, transform.y + HEIGHT - SLOT_SIZE - SLOT_OFFSET}, SLOT_SIZE, SLOT_SIZE, SLOT_COLOR, 2)
            }
        }
    }
}

draw_rectangle_border :: proc(pos: rl.Vector2, width: i32, height: i32, color: rl.Color, weight: i32) {
    rl.DrawRectangle(cast(i32)pos.x, cast(i32)pos.y, width, weight, color)
    rl.DrawRectangle(cast(i32)pos.x, cast(i32)pos.y, weight, height, color)
    rl.DrawRectangle(cast(i32)pos.x, cast(i32)pos.y + height - weight, width, weight, color)
    rl.DrawRectangle(cast(i32)pos.x + width - weight, cast(i32)pos.y, weight, height, color)
}
