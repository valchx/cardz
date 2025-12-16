const std = @import("std");
const rl = @import("raylib");

const Context = @import("Context.zig");
const Hand = @import("Hand.zig");
const Card = @import("Card.zig");
const Board = @import("Board.zig");
const Deck = @import("Deck.zig");

const Self = @This();

board: Board,
player_hand: Hand,
dealer_hand: Hand,
deck: Deck,

pub fn init(ctx: *const Context) !Self {
    var self = Self{
        .board = try .init(
            rl.Vector2.init(
                @floatFromInt(rl.getScreenWidth()),
                @floatFromInt(rl.getScreenHeight()),
            ),
        ),
        .player_hand = try Hand.init(),
        .dealer_hand = try Hand.init(),
        .deck = try .init(),
    };

    try self.reset();


    try self.board.addDropZone(.init(( ctx.screen_size.x / 2 ) - 100, 200));
    try self.board.addDropZone(.init(( ctx.screen_size.x / 2 ) + 100, 200));

    return self;
}

fn reset(self: *Self) !void {
    try self.deck.reset();
}

pub fn deinit(self: *Self) void {
    for (self.deck.items) |*card| {
        card.deinit();
    }
    self.deck.deinit(self._deck_alloc.allocator());
    self._deck_alloc.deinit();

    self.dealer_hand.deinit();
    self.player_hand.deinit();
}

pub fn draw(self: Self, ctx: *const Context) void {
    self.board.draw(ctx);

    self.player_hand.draw();
    self.dealer_hand.draw();
}

pub fn update(self: *Self) void {
    self.player_hand.update(self.board.drop_zones.items);
    self.dealer_hand.update(self.board.drop_zones.items);
}
