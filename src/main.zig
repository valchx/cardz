const std = @import("std");
const rl = @import("raylib");

const Game = @import("Game.zig");
const Hand = @import("Hand.zig");
const Card = @import("Card.zig");

pub fn main() anyerror!void {
    const screen_size = rl.Vector2.init(800, 450);

    rl.initWindow(@intFromFloat(screen_size.x), @intFromFloat(screen_size.y), "BlackJack");
    defer rl.closeWindow();

    rl.setTargetFPS(1000);

    var game = try Game.init();

    const card = game.deck.items[0];
    // card.debug = true;
    try game.player_hand.add_card(card);

    std.debug.print("card: {}\n", .{card});

    while (!rl.windowShouldClose()) {
        // Update
        game.player_hand.update();

        // Draw
        rl.beginDrawing();
        defer rl.endDrawing();

        rl.clearBackground(.dark_green);

        game.player_hand.draw();
    }
}
