package main

import rl "vendor:raylib"

Fixed :: struct { value: f32 }
Grow  :: struct { weight: f32 }
Fit   :: struct {}

SizeMode :: union { Fixed, Grow, Fit }

NodeSize :: struct {
    width:  SizeMode,
    height: SizeMode,
}

Spacing :: struct {
    top:    f32,
    right:  f32,
    bottom: f32,
    left:   f32,
}

spacing :: proc { spacing_uniform, spacing_xy, spacing_full }

spacing_uniform :: proc(all: f32) -> Spacing {
    return { all, all, all, all }
}

spacing_xy :: proc(x: f32, y: f32) -> Spacing {
    return { y, x, y, x }
}

spacing_full :: proc(top: f32, right: f32, bottom: f32, left: f32) -> Spacing {
    return { top, right, bottom, left }
}

Relative :: struct {}

Absolute :: struct {
    top:    Maybe(f32),
    right:  Maybe(f32),
    bottom: Maybe(f32),
    left:   Maybe(f32),
}

Position :: union { Relative, Absolute }

absolute :: proc(
    top:    Maybe(f32) = nil,
    right:  Maybe(f32) = nil,
    bottom: Maybe(f32) = nil,
    left:   Maybe(f32) = nil,
) -> Position {
    return Absolute { top, right, bottom, left }
}

Direction :: enum { Row, Column }

Justify :: enum { Start, Center, End, Space_Between }

Align :: enum { Start, Center, End }

Border :: struct {
    color: rl.Color,
    width: f32,
}

Node :: union {
    Layout_Node,
    Text_Node,
}

Layout_Node :: struct {
    id:         Maybe(cstring),
    size:       NodeSize,
    position:   Position,
    direction:  Direction,
    gap:        f32,
    padding:    Spacing,
    margin:     Spacing,
    justify:    Justify,
    align:      Align,
    background: rl.Color,
    border:     Border,
    children:   [dynamic]^Node,
    computed_pos:  rl.Vector2,
    computed_size: rl.Vector2,
}

Text_Node :: struct {
    id:        Maybe(cstring),
    text:      cstring,
    font_size: f32,
    color:     rl.Color,
    margin:    Spacing,
    position:  Position,
    computed_pos:  rl.Vector2,
    computed_size: rl.Vector2,
}

fixed :: proc(w: f32, h: f32) -> NodeSize {
    return { width = Fixed{w}, height = Fixed{h} }
}

grow :: proc(w: f32 = 1, h: f32 = 1) -> NodeSize {
    return { width = Grow{w}, height = Grow{h} }
}

fit :: proc() -> NodeSize {
    return { width = Fit{}, height = Fit{} }
}

layout :: proc(
    size: NodeSize,
    id: Maybe(cstring) = nil,
    dir: Direction = .Column,
    pos: Position = Relative{},
    gap: f32 = 0,
    padding: Spacing = {},
    margin: Spacing = {},
    justify: Justify = .Start,
    align: Align = .Start,
    bg: rl.Color = rl.BLANK,
    border: Border = {},
    children: ..^Node,
) -> ^Node {
    n := new(Node)
    kids: [dynamic]^Node
    for c in children { append(&kids, c) }
    n^ = Layout_Node {
        id         = id,
        size       = size,
        position   = pos,
        direction  = dir,
        gap        = gap,
        padding    = padding,
        margin     = margin,
        justify    = justify,
        align      = align,
        background = bg,
        border     = border,
        children   = kids,
    }
    return n
}

text :: proc(
    t: cstring,
    id: Maybe(cstring) = nil,
    size: f32 = 18,
    color: rl.Color = rl.WHITE,
    margin: Spacing = {},
    pos: Position = Relative{},
) -> ^Node {
    n := new(Node)
    n^ = Text_Node {
        id        = id,
        text      = t,
        font_size = size,
        color     = color,
        margin    = margin,
        position  = pos,
    }
    return n
}

is_absolute :: proc(node: ^Node) -> bool {
    switch v in node^ {
    case Layout_Node:
        _, ok := v.position.(Absolute)
        return ok
    case Text_Node:
        _, ok := v.position.(Absolute)
        return ok
    }
    return false
}

get_margin :: proc(node: ^Node) -> Spacing {
    switch v in node^ {
    case Layout_Node: return v.margin
    case Text_Node:   return v.margin
    }
    return {}
}

get_computed_size :: proc(node: ^Node) -> rl.Vector2 {
    switch v in node^ {
    case Layout_Node: return v.computed_size
    case Text_Node:   return v.computed_size
    }
    return {}
}

set_computed_pos :: proc(node: ^Node, pos: rl.Vector2) {
    switch &v in node^ {
    case Layout_Node: v.computed_pos = pos
    case Text_Node:   v.computed_pos = pos
    }
}

set_computed_size :: proc(node: ^Node, size: rl.Vector2) {
    switch &v in node^ {
    case Layout_Node: v.computed_size = size
    case Text_Node:   v.computed_size = size
    }
}

compute_layout :: proc(root: ^Node, font: rl.Font, screen_w: f32, screen_h: f32) {
    measure_node(root, font)
    layout_node(root, screen_w, screen_h, 0, 0)
}

measure_node :: proc(node: ^Node, font: rl.Font) {
    switch &v in node^ {
    case Text_Node:
        measurement := rl.MeasureTextEx(font, v.text, v.font_size, 0)
        v.computed_size = measurement + {
            v.margin.left + v.margin.right,
            v.margin.top + v.margin.bottom,
        }

    case Layout_Node:
        for c in v.children {
            measure_node(c, font)
        }

        relative_count: f32 = 0
        for c in v.children {
            if !is_absolute(c) { relative_count += 1 }
        }
        total_gap := max(0, relative_count - 1) * v.gap

        content_w: f32 = 0
        content_h: f32 = 0

        for c in v.children {
            if is_absolute(c) { continue }
            cs := get_computed_size(c)

            switch v.direction {
            case .Row:
                content_w += cs.x
                content_h = max(content_h, cs.y)
            case .Column:
                content_w = max(content_w, cs.x)
                content_h += cs.y
            }
        }

        switch v.direction {
        case .Row:    content_w += total_gap
        case .Column: content_h += total_gap
        }

        content_w += v.padding.left + v.padding.right
        content_h += v.padding.top + v.padding.bottom

        v.computed_size.x = resolve_size_mode(v.size.width, content_w)
        v.computed_size.y = resolve_size_mode(v.size.height, content_h)
    }
}

resolve_size_mode :: proc(mode: SizeMode, content: f32) -> f32 {
    switch s in mode {
    case Fixed: return s.value
    case Fit:   return content
    case Grow:  return 0
    }
    return content
}

layout_node :: proc(node: ^Node, available_w: f32, available_h: f32, pos_x: f32, pos_y: f32) {
    switch &v in node^ {
    case Text_Node:
        v.computed_pos = { pos_x + v.margin.left, pos_y + v.margin.top }

    case Layout_Node:
        v.computed_size.x = resolve_layout_size(v.size.width, v.computed_size.x, available_w - v.margin.left - v.margin.right)
        v.computed_size.y = resolve_layout_size(v.size.height, v.computed_size.y, available_h - v.margin.top - v.margin.bottom)
        v.computed_pos = { pos_x + v.margin.left, pos_y + v.margin.top }

        inner_w := v.computed_size.x - v.padding.left - v.padding.right
        inner_h := v.computed_size.y - v.padding.top - v.padding.bottom

        relative_children: [dynamic]^Node
        defer delete(relative_children)
        for c in v.children {
            if !is_absolute(c) { append(&relative_children, c) }
        }

        rel_count := cast(f32)len(relative_children)
        total_gap := max(0, rel_count - 1) * v.gap

        fixed_total: f32 = 0
        flex_total_weight: f32 = 0

        for c in relative_children {
            m := get_margin(c)
            switch &cv in c^ {
            case Layout_Node:
                main_size := get_child_main_size(cv.size, v.direction)
                switch s in main_size {
                case Fixed, Fit:
                    cs := get_computed_size(c)
                    if v.direction == .Row {
                        fixed_total += cs.x
                    } else {
                        fixed_total += cs.y
                    }
                case Grow:
                    flex_total_weight += s.weight
                }
            case Text_Node:
                cs := get_computed_size(c)
                if v.direction == .Row {
                    fixed_total += cs.x
                } else {
                    fixed_total += cs.y
                }
            }
        }

        main_space := inner_w if v.direction == .Row else inner_h
        remaining := main_space - fixed_total - total_gap

        if flex_total_weight > 0 && remaining > 0 {
            for c in relative_children {
                switch &cv in c^ {
                case Layout_Node:
                    main_sm := get_child_main_size(cv.size, v.direction)
                    if g, ok := main_sm.(Grow); ok {
                        flex_size := (g.weight / flex_total_weight) * remaining
                        if v.direction == .Row {
                            cv.computed_size.x = flex_size
                        } else {
                            cv.computed_size.y = flex_size
                        }
                    }
                case Text_Node:
                }
            }
        }

        content_main: f32 = 0
        for c in relative_children {
            cs := get_computed_size(c)
            content_main += cs.x if v.direction == .Row else cs.y
        }
        content_main += total_gap

        main_offset: f32 = 0
        extra_gap: f32 = 0
        extra_space := main_space - content_main

        switch v.justify {
        case .Start:
            main_offset = 0
        case .Center:
            main_offset = extra_space / 2
        case .End:
            main_offset = extra_space
        case .Space_Between:
            if rel_count > 1 {
                extra_gap = extra_space / (rel_count - 1)
            }
        }

        cross_space := inner_h if v.direction == .Row else inner_w

        cursor := main_offset
        for i := 0; i < len(relative_children); i += 1 {
            c := relative_children[i]
            cs := get_computed_size(c)
            m := get_margin(c)

            child_main := cs.x if v.direction == .Row else cs.y
            child_cross := cs.y if v.direction == .Row else cs.x

            cross_offset: f32 = 0
            switch v.align {
            case .Start:  cross_offset = 0
            case .Center: cross_offset = (cross_space - child_cross) / 2
            case .End:    cross_offset = cross_space - child_cross
            }

            child_x: f32
            child_y: f32
            if v.direction == .Row {
                child_x = v.computed_pos.x + v.padding.left + cursor
                child_y = v.computed_pos.y + v.padding.top + cross_offset
            } else {
                child_x = v.computed_pos.x + v.padding.left + cross_offset
                child_y = v.computed_pos.y + v.padding.top + cursor
            }

            child_avail_w := cs.x if v.direction == .Row else inner_w
            child_avail_h := cs.y if v.direction == .Column else inner_h

            resolve_child_cross_axis(c, v.direction, cross_space)

            layout_node(c, child_avail_w, child_avail_h, child_x, child_y)

            cursor += child_main + v.gap + extra_gap
        }

        for c in v.children {
            if !is_absolute(c) { continue }

            abs_config: Absolute

            switch &cv in c^ {
            case Layout_Node:
                abs_config = cv.position.(Absolute)
            case Text_Node:
                abs_config = cv.position.(Absolute)
            }

            cs := get_computed_size(c)

            switch &cv in c^ {
            case Layout_Node:
                cv.computed_size.x = resolve_layout_size(cv.size.width, cv.computed_size.x, v.computed_size.x - v.padding.left - v.padding.right)
                cv.computed_size.y = resolve_layout_size(cv.size.height, cv.computed_size.y, v.computed_size.y - v.padding.top - v.padding.bottom)
                cs = cv.computed_size
            case Text_Node:
            }

            child_x: f32 = v.computed_pos.x
            child_y: f32 = v.computed_pos.y

            if l, ok := abs_config.left.?; ok {
                child_x = v.computed_pos.x + l
            } else if r, ok := abs_config.right.?; ok {
                child_x = v.computed_pos.x + v.computed_size.x - cs.x - r
            }

            if t, ok := abs_config.top.?; ok {
                child_y = v.computed_pos.y + t
            } else if b, ok := abs_config.bottom.?; ok {
                child_y = v.computed_pos.y + v.computed_size.y - cs.y - b
            }

            layout_node(c, cs.x, cs.y, child_x, child_y)
        }
    }
}

resolve_layout_size :: proc(mode: SizeMode, measured: f32, available: f32) -> f32 {
    switch s in mode {
    case Fixed: return s.value
    case Fit:   return measured
    case Grow:  return available
    }
    return measured
}

get_child_main_size :: proc(size: NodeSize, dir: Direction) -> SizeMode {
    switch dir {
    case .Row:    return size.width
    case .Column: return size.height
    }
    return size.height
}

resolve_child_cross_axis :: proc(node: ^Node, parent_dir: Direction, cross_space: f32) {
    switch &v in node^ {
    case Layout_Node:
        cross_mode: SizeMode
        switch parent_dir {
        case .Row:    cross_mode = v.size.height
        case .Column: cross_mode = v.size.width
        }
        if _, ok := cross_mode.(Grow); ok {
            m := v.margin
            if parent_dir == .Row {
                v.computed_size.y = cross_space - m.top - m.bottom
            } else {
                v.computed_size.x = cross_space - m.left - m.right
            }
        }
    case Text_Node:
    }
}

NodeEvent :: struct {
    hovered:       bool,
    pressed:       bool,
    just_pressed:  bool,
    just_released: bool,
}

InteractionState :: struct {
    mouse_pos:       rl.Vector2,
    mouse_down:      bool,
    prev_mouse_down: bool,
    events:          map[cstring]NodeEvent,
    press_target:    Maybe(cstring),
}

update_interaction_input :: proc(state: ^InteractionState) {
    state.prev_mouse_down = state.mouse_down
    state.mouse_pos = rl.GetMousePosition()
    state.mouse_down = rl.IsMouseButtonDown(.LEFT)
}

get_event :: proc(state: ^InteractionState, id: cstring) -> NodeEvent {
    ev, ok := state.events[id]
    if ok { return ev }
    return {}
}

process_interactions :: proc(state: ^InteractionState, root: ^Node) {
    clear(&state.events)

    topmost_hit: Maybe(cstring)
    hit_test_node(root, state.mouse_pos, &topmost_hit)

    mouse_just_down := state.mouse_down && !state.prev_mouse_down
    mouse_just_up := !state.mouse_down && state.prev_mouse_down

    if hit, ok := topmost_hit.?; ok {
        ev := state.events[hit]
        ev.hovered = true
        state.events[hit] = ev
    }

    if mouse_just_down {
        if hit, ok := topmost_hit.?; ok {
            state.press_target = hit
            ev := state.events[hit]
            ev.just_pressed = true
            ev.pressed = true
            state.events[hit] = ev
        }
    }

    if state.mouse_down {
        if target, ok := state.press_target.?; ok {
            ev := state.events[target]
            ev.pressed = true
            state.events[target] = ev
        }
    }

    if mouse_just_up {
        if target, ok := state.press_target.?; ok {
            ev := state.events[target]
            ev.just_released = true
            ev.pressed = false
            state.events[target] = ev
            state.press_target = nil
        }
    }
}

get_node_id :: proc(node: ^Node) -> Maybe(cstring) {
    switch v in node^ {
    case Layout_Node: return v.id
    case Text_Node:   return v.id
    }
    return nil
}

get_node_bounds :: proc(node: ^Node) -> (rl.Vector2, rl.Vector2) {
    switch v in node^ {
    case Layout_Node: return v.computed_pos, v.computed_size
    case Text_Node:   return v.computed_pos, v.computed_size
    }
    return {}, {}
}

point_in_rect :: proc(point: rl.Vector2, pos: rl.Vector2, size: rl.Vector2) -> bool {
    return point.x >= pos.x && point.x <= pos.x + size.x &&
           point.y >= pos.y && point.y <= pos.y + size.y
}

hit_test_node :: proc(node: ^Node, mouse_pos: rl.Vector2, hit: ^Maybe(cstring)) {
    if id, ok := get_node_id(node).?; ok {
        pos, size := get_node_bounds(node)
        if point_in_rect(mouse_pos, pos, size) {
            hit^ = id
        }
    }

    switch v in node^ {
    case Layout_Node:
        for c in v.children {
            if !is_absolute(c) { hit_test_node(c, mouse_pos, hit) }
        }
        for c in v.children {
            if is_absolute(c) { hit_test_node(c, mouse_pos, hit) }
        }
    case Text_Node:
    }
}
