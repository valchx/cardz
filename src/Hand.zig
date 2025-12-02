const std = @import("std");

const Card = @import("./Card.zig");

const Self = @This();

cards: std.ArrayList(Card),
_alloc: std.heap.ArenaAllocator,

pub fn init() !Self {
    var arena = std.heap.ArenaAllocator.init(std.heap.page_allocator);
    return .{
        .cards = try std.ArrayList(Card).initCapacity(arena.allocator(), 7),
        ._alloc = arena,
    };
}

pub fn deinit(self: *Self) void {
    for (self.cards.items) |*card| {
        card.deinit();
    }

    self.cards.deinit(self._alloc.allocator());
    self._alloc.deinit();
}

pub fn add_card(self: *Self, card: Card) !void {
    try self.cards.append(self._alloc.allocator(), card);
}

pub fn draw(self: Self) void {
    for (self.cards.items) |item| {
        item.draw();
    }
}

pub fn update(self: Self) void {
    for (self.cards.items) |*item| {
        item.update();
    }
}
