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
    texture: rl.Texture2D,
}

SlotData :: struct {
    pos: SlotPosition,
}

ui_tree :: proc(global: ^GlobalState) -> ^Node {
    ui := &global.ui

    boomerang := CardData {
        "Boomerang",
        rl.GREEN,
        rl.BLACK,
        false,
        {.BOTTOM_LEFT, .TOP_RIGHT},
        get_texture(&global.textures, "boomerang"),
    }

    fire_wand := CardData {
        "Fire Wand",
        rl.RED,
        rl.WHITE,
        false,
        {.BOTTOM_LEFT, .TOP_RIGHT},
        get_texture(&global.textures, "wand"),
    }

    ice_shuriken := CardData {
        "Ice Shuriken",
        rl.Color{100, 180, 255, 255},
        rl.BLACK,
        false,
        {.TOP_LEFT, .BOTTOM_RIGHT},
        get_texture(&global.textures, "shuriken"),
    }

    return layout(ui,
        size = grow(),
        dir = .Column,
        padding = spacing(50),
        gap = 8,
        children = {
            layout(ui, size = {width = Grow{1}, height = Fit{}}, dir = .Row, gap = 8,
                children = {
                    card_ui(boomerang, ui),
                    card_ui(fire_wand, ui),
                    card_ui(ice_shuriken, ui),
                },
            ),
        },
    )
}

card_ui :: proc(card: CardData, ui: ^UI) -> ^Node {
    ev, idx := get_events(ui)

    bg_color := rl.BLACK
    if ev.hovered { bg_color = rl.Color{25, 25, 25, 255} }

    return layout(ui,
        size = fixed(110, 125),
        reserved_idx = idx,
        border = Border{card.bg, 1},
        bg = bg_color,
        children = {
            layout(ui, size = {width = Grow{1}, height = Fit{}}, padding = spacing(2), bg = card.bg,
                children = {
                    text(ui, card.label, color = card.fg),
                },
            ),
            layout(ui, size = grow(), justify = .Center, align = .Center,
                children = {
                    layout(ui, size = fixed(50, 50), texture = card.texture, tint = card.bg, object_fit = .Contain),
                    slot_ui(SlotData{.TOP_RIGHT}, ui),
                    slot_ui(SlotData{.BOTTOM_RIGHT}, ui),
                },
            ),
        },
    )
}

slot_ui :: proc(slot: SlotData, ui: ^UI) -> ^Node {
    ev, idx := get_events(ui)

    border_color: rl.Color = {128, 128, 128, 255}
    if ev.hovered { border_color = {158, 158, 158, 255} }

    OFFSET: f32 = 8
    pos: Position = Absolute{}

    if slot.pos == .TOP_LEFT { pos = Absolute{top = OFFSET, left = OFFSET} }
    if slot.pos == .TOP_RIGHT { pos = Absolute{top = OFFSET, right = OFFSET} }
    if slot.pos == .BOTTOM_LEFT { pos = Absolute{bottom = OFFSET, left = OFFSET} }
    if slot.pos == .BOTTOM_RIGHT { pos = Absolute{bottom = OFFSET, right = OFFSET} }

    return layout(ui,
        size = fixed(11, 11),
        reserved_idx = idx,
        pos = pos,
        border = Border{border_color, 2},
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

        if tex, ok := v.texture.?; ok {
            tex_w := cast(f32)tex.width
            tex_h := cast(f32)tex.height
            source := rl.Rectangle{0, 0, tex_w, tex_h}
            dest: rl.Rectangle

            switch v.object_fit {
            case .Fill:
                dest = {pos.x, pos.y, sz.x, sz.y}
            case .Contain:
                scale := min(sz.x / tex_w, sz.y / tex_h)
                w := tex_w * scale
                h := tex_h * scale
                dest = {pos.x + (sz.x - w) / 2, pos.y + (sz.y - h) / 2, w, h}
            case .Cover:
                scale := max(sz.x / tex_w, sz.y / tex_h)
                crop_x := (tex_w - sz.x / scale) / 2
                crop_y := (tex_h - sz.y / scale) / 2
                source = {crop_x, crop_y, tex_w - crop_x * 2, tex_h - crop_y * 2}
                dest = {pos.x, pos.y, sz.x, sz.y}
            }

            rl.DrawTexturePro(tex, source, dest, {0, 0}, 0, v.tint)
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
