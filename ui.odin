package main
import rl "vendor:raylib"

Size :: struct {
    width: i32,
    height: i32
}

Node :: union {
    Layout_Node,
    Text_Node,
}


Border :: struct {
    color: rl.Color,
    width: i32,
}

Layout_Node :: struct {
    pos: rl.Vector2,
    size: Size,
    background: rl.Color,
    border: Border,
    children: [dynamic]^Node,
}

layout :: proc(
    pos: rl.Vector2, 
    size: Size, 
    bg: rl.Color = rl.BLANK, 
    border: Border = {},
    children: ..^Node,
) -> ^Node {
    n := new(Node)
    kids: [dynamic]^Node
    for c in children { append(&kids, c) }
    n^ = Layout_Node { pos, size, bg, border, kids }
    return n
}

Text_Node :: struct {
    pos: rl.Vector2,
    size: Size,
    text: cstring,
    font_size: f32,
    color: rl.Color,
}

text :: proc(pos: rl.Vector2, t: cstring, font_size: f32, color: rl.Color) -> ^Node {
    n := new(Node)
    n^ = Text_Node { pos, {}, t, font_size, color }
    return n
}

SlotPositions :: enum i32 {
    TOP_LEFT,
    TOP_RIGHT,
    BOTTOM_LEFT,
    BOTTOM_RIGHT,
}

CardData :: struct {
    pos: rl.Vector2,
	label: cstring,
	bg: rl.Color,
    fg: rl.Color,
    flipped: bool,
    slots: bit_set[SlotPositions; i32],
}

InteractionData :: struct {
    hovered: bool
}

SlotData :: struct {
    pos: rl.Vector2,
    size: i32
}

ui_tree :: proc() -> ^Node {

    return layout({200,200}, {500, 500},
        children = {
            card_ui(
                CardData{
                    {10.0, 10.0},
                    "Boomerang", 
                    rl.Color{0, 255, 0, 255},
                    rl.BLACK,
                    false,
                    {.TOP_LEFT, .TOP_RIGHT, .BOTTOM_RIGHT}
                }
            )
        }
    )
}

card_ui :: proc(CardData) -> ^Node {
    return layout({10, 10}, {100.0, 120.0},
        border = Border{rl.RED}
    )
}

draw_ui :: proc(global: ^GlobalState, parent: ^Node, parent_position: rl.Vector2) {
    switch v in parent {
    case Layout_Node:
        abs_pos := parent_position + v.pos
        if v.background.a > 0 {
            rl.DrawRectangle(cast(i32)abs_pos.x, cast(i32)abs_pos.y, v.size.width, v.size.height, v.background)
        }
        if v.border.width > 0 {
            draw_rectangle_border(abs_pos, v.size.width, v.size.height, v.border.color, v.border.width)
        }
        for c in v.children {
            draw_ui(global, c, abs_pos)
        }

    case Text_Node:
        rl.DrawTextEx(global.font, v.text, parent_position + v.pos, v.font_size, 0, v.color)
    }
}

create_card_system :: System {
    proc(global: ^GlobalState) {
        entity := create_entity(&global.world)
        add_component(&global.world.render, entity, RenderData{})
        add_component(
            &global.world.cards, 
            entity, 
            CardData{
                "Boomerang", 
                rl.Color{0, 255, 0, 255},
                rl.BLACK,
                false,
                {.TOP_LEFT, .TOP_RIGHT, .BOTTOM_RIGHT},
                {10.0, 10.0}
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

            // mouse_pos = rl.GetMousePosition()

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
