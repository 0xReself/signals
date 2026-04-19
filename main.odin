package main

import "core:fmt"
import rl "vendor:raylib"

main :: proc() {
    SCREEN_WIDTH :: 800
    SCREEN_HEIGHT :: 450

    rl.InitWindow(SCREEN_WIDTH, SCREEN_HEIGHT, "Signals")
    
    player_pos := rl.Vector2{SCREEN_WIDTH/2, SCREEN_HEIGHT/2}

    rl.SetTargetFPS(144)

    for !rl.WindowShouldClose() {
        if rl.IsKeyDown(.ESCAPE) {
            break;
        }

        if rl.IsKeyDown(.D) {
            player_pos.x += 5
        }
        if rl.IsKeyDown(.A) {
            player_pos.x -= 5
        }
        if rl.IsKeyDown(.W) {
            player_pos.y -= 5
        }
        if rl.IsKeyDown(.S) {
            player_pos.y += 5
        }

        rl.BeginDrawing()
        rl.ClearBackground(rl.RAYWHITE)
        rl.DrawCircleV(player_pos, 25, rl.MAROON)

        rl.EndDrawing()
    }

    rl.CloseWindow()
}
