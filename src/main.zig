const std = @import("std");
const rl = @import("raylib");

const Card = @import("card.zig");

pub fn main() anyerror!void {
    const screen_size = rl.Vector2.init(800, 450);

    rl.initWindow(@intFromFloat(screen_size.x), @intFromFloat(screen_size.y), "BlackJack");
    defer rl.closeWindow();

    rl.setTargetFPS(1000);

    var card = try Card.init(screen_size);
    defer card.deinit();

    card.debug = true;

    std.debug.print("card: {}\n", .{card});

    while (!rl.windowShouldClose()) {
        // Update
        card.update();

        // Draw
        rl.beginDrawing();
        defer rl.endDrawing();

        rl.clearBackground(.dark_green);

        card.draw();
    }
}
