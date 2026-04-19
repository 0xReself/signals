package main

import rl "vendor:raylib"

SlotPosition :: enum i32 {
    TOP_LEFT,
    TOP_RIGHT,
    BOTTOM_LEFT,
    BOTTOM_RIGHT,
}

CardData :: struct {
    label:   cstring,
    bg:      rl.Color,
    fg:      rl.Color,
    flipped: bool,
    slots:   bit_set[SlotPosition; i32],
}

SlotData :: struct {
    pos: SlotPosition,
}

ui_tree :: proc(state: ^InteractionState) -> ^Node {
    card_data := CardData {
        "Boomerang",
        rl.GREEN,
        rl.BLACK,
        false,
        {.BOTTOM_LEFT, .TOP_RIGHT},
    }

    return layout(
        size = grow(),
        dir = .Column,
        padding = spacing(50),
        gap = 8,
        children = {
            layout(
                size = {width = Grow{1}, height = Fit{}},
                dir = .Row,
                gap = 8,
                children = {
                    card_ui(card_data, "card-1", state),
                    card_ui(card_data, "card-2", state),
                    card_ui(card_data, "card-3", state),
                },
            ),
        },
    )
}

card_ui :: proc(card: CardData, id: cstring, state: ^InteractionState) -> ^Node {
    ev := get_event(state, id)

    bg_color := rl.BLACK 
    if ev.hovered { bg_color = rl.Color{25,25,25,255} }

    return layout(
        id = id,
        size = fixed(110, 125),
        border = Border{card.bg, 1},
        bg = bg_color,
        children = {
            layout(
                size = {width = Grow{1}, height = Fit{}},
                padding = spacing(2),
                bg = card.bg,
                children = {
                    text(card.label, color = card.fg),
                },
            ),
            layout(
                size = grow(),
                pos = Relative{},
                children = {
                    slot_ui(SlotData{.TOP_RIGHT}, "slot-1", state),
                    slot_ui(SlotData{.BOTTOM_RIGHT}, "slot-2", state)
                }
            ),
        },
    )
}

slot_ui :: proc(slot: SlotData, id: cstring, state: ^InteractionState) -> ^Node {
    ev := get_event(state, id)

    border_color := rl.Color{128, 128, 128, 255} 
    if ev.hovered { border_color = rl.Color{158,158,158,255} }

    OFFSET :: 8
    pos := Absolute{}

    if slot.pos == .TOP_LEFT { pos = Absolute {top = OFFSET, left = OFFSET} }
    if slot.pos == .TOP_RIGHT { pos = Absolute {top = OFFSET, right = OFFSET} }
    if slot.pos == .BOTTOM_LEFT { pos = Absolute {bottom = OFFSET, left = OFFSET} }
    if slot.pos == .BOTTOM_RIGHT { pos = Absolute {bottom = OFFSET, right = OFFSET} }

    return layout(
        id = id,
        size = fixed(11, 11),
        pos = pos, 
        border = Border{border_color, 2}
    )
}

draw_ui :: proc(global: ^GlobalState, node: ^Node) {
    switch v in node {
    case Layout_Node:
        pos := v.computed_pos
        sz := v.computed_size

        if v.background.a > 0 {
            rl.DrawRectangle(
                cast(i32)pos.x, cast(i32)pos.y,
                cast(i32)sz.x, cast(i32)sz.y,
                v.background,
            )
        }

        if v.border.width > 0 {
            draw_rectangle_border(pos, sz.x, sz.y, v.border.color, v.border.width)
        }

        for c in v.children {
            if !is_absolute(c) { draw_ui(global, c) }
        }
        for c in v.children {
            if is_absolute(c) { draw_ui(global, c) }
        }

    case Text_Node:
        rl.DrawTextEx(
            global.font, v.text,
            v.computed_pos,
            v.font_size, 0, v.color,
        )
    }
}

draw_rectangle_border :: proc(pos: rl.Vector2, width: f32, height: f32, color: rl.Color, weight: f32) {
    w := cast(i32)weight
    rl.DrawRectangle(cast(i32)pos.x, cast(i32)pos.y, cast(i32)width, w, color)
    rl.DrawRectangle(cast(i32)pos.x, cast(i32)pos.y, w, cast(i32)height, color)
    rl.DrawRectangle(cast(i32)pos.x, cast(i32)pos.y + cast(i32)height - w, cast(i32)width, w, color)
    rl.DrawRectangle(cast(i32)pos.x + cast(i32)width - w, cast(i32)pos.y, w, cast(i32)height, color)
}
