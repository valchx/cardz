const std = @import("std");

const Hand = @import("Hand.zig");
const Card = @import("Card.zig");

const Self = @This();

player_hand: Hand,
dealer_hand: Hand,
deck: std.ArrayList(Card),
_deck_alloc: std.mem.Allocator,

pub fn init() !Self {
    var deck_arena = std.heap.ArenaAllocator.init(std.heap.page_allocator);

    const deck = try std.ArrayList(Card).initCapacity(
        deck_arena.allocator(),
        0,
    );

    var self = Self{
        .player_hand = try Hand.init(),
        .dealer_hand = try Hand.init(),
        .deck = deck,
        ._deck_alloc = deck_arena.allocator(),
    };

    try self.reset();

    return self;
}

fn reset(self: *Self) !void {
    for (self.deck.items) |*card| {
        card.deinit();
    }
    self.deck.clearAndFree(self._deck_alloc);

    inline for (std.meta.fields(Card.Rank)) |rank_field| {
        inline for (std.meta.fields(Card.Suite)) |suite_field| {
            try self.deck.append(
                self._deck_alloc,
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
    self.deck.deinit(self._deck_alloc);

    self.dealer_hand.deinit();
    self.player_hand.deinit();
}
