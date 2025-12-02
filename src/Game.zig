const std = @import("std");
const rl = @import("raylib");

const Context = @import("Context.zig");
const Hand = @import("Hand.zig");
const Card = @import("Card.zig");
const Board = @import("Board.zig");

const Self = @This();

board: Board,
player_hand: Hand,
dealer_hand: Hand,
deck: std.ArrayList(Card),
_deck_alloc: std.heap.ArenaAllocator,

pub fn init() !Self {
    var deck_arena = std.heap.ArenaAllocator.init(std.heap.page_allocator);

    const deck = try std.ArrayList(Card).initCapacity(
        deck_arena.allocator(),
        0,
    );

    var self = Self{
        .board = try .init(
            rl.Vector2.init(
                @floatFromInt(rl.getScreenWidth()),
                @floatFromInt(rl.getScreenHeight()),
            ),
        ),
        .player_hand = try Hand.init(),
        .dealer_hand = try Hand.init(),
        .deck = deck,
        ._deck_alloc = deck_arena,
    };

    try self.reset();

    return self;
}

fn reset(self: *Self) !void {
    for (self.deck.items) |*card| {
        card.deinit();
    }

    _ = self._deck_alloc.reset(.free_all);

    self.deck = try .initCapacity(self._deck_alloc.allocator(), 0);

    inline for (std.meta.fields(Card.Rank)) |rank_field| {
        inline for (std.meta.fields(Card.Suite)) |suite_field| {
            try self.deck.append(
                self._deck_alloc.allocator(),
                try Card.init(.{
                    .rank = @enumFromInt(rank_field.value),
                    .suite = @enumFromInt(suite_field.value),
                }),
            );
        }
    }

    const seed = std.time.milliTimestamp();
    var prng = std.Random.DefaultPrng.init(@intCast(seed));
    const random = prng.random();

    std.Random.shuffle(random, Card, self.deck.items);
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

pub fn update(self: Self) void {
    self.player_hand.update();
    self.dealer_hand.update();
}
