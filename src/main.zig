const std = @import("std");
const rl = @import("raylib");

const Context = @import("Context.zig");
const Game = @import("Game.zig");
const Hand = @import("Hand.zig");
const Card = @import("Card.zig");

pub fn main() anyerror!void {
    const screen_size = rl.Vector2.init(800, 450);

    rl.setConfigFlags(.{ .window_resizable = true, });

    rl.initWindow(@intFromFloat(screen_size.x), @intFromFloat(screen_size.y), "Cardz");
    defer rl.closeWindow();

    rl.setTargetFPS(120);

    var ctx: Context = .{
        .world_to_screen_scale = 1,
        .screen_size = screen_size.addValue(0),
    };

    var game = try Game.init(&ctx);

    const card = game.deck.cards.items[0];
    // card.debug = true;
    try game.player_hand.add_card(card);

    while (!rl.windowShouldClose()) {
        ctx.screen_size = .init(
            @floatFromInt(rl.getScreenWidth()),
            @floatFromInt(rl.getScreenHeight()),
        );

        // Update
        game.update();

        // Draw
        rl.beginDrawing();
        defer rl.endDrawing();

        game.draw(&ctx);
    }
}
