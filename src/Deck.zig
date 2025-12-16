const std = @import("std");
const rl = @import("raylib");

const Card = @import("Card.zig");

const Self = @This();

cards: std.ArrayList(Card),
_cards_arena: std.heap.ArenaAllocator,

pub fn init() !Self {
    var cards_arena = std.heap.ArenaAllocator.init(std.heap.page_allocator);

    const cards = try std.ArrayList(Card).initCapacity(
        cards_arena.allocator(),
        0,
    );

    return .{
        .cards = cards,
        ._cards_arena = cards_arena,
    };
}

pub fn deinit(self: *Self) void {
    self._cards_arena.deinit();
}

pub fn reset(self: *Self) !void {
    for (self.cards.items) |*card| {
        card.deinit();
    }

    _ = self._cards_arena.reset(.free_all);

    self.cards = try .initCapacity(self._cards_arena.allocator(), 0);

    inline for (std.meta.fields(Card.Rank)) |rank_field| {
        inline for (std.meta.fields(Card.Suite)) |suite_field| {
            try self.cards.append(
                self._cards_arena.allocator(),
                try Card.init(
                    .{
                        .rank = @enumFromInt(rank_field.value),
                        .suite = @enumFromInt(suite_field.value),
                    },
                ),
            );
        }
    }

    const seed = std.time.milliTimestamp();
    var prng = std.Random.DefaultPrng.init(@intCast(seed));
    const random = prng.random();

    std.Random.shuffle(random, Card, self.cards.items);
}
