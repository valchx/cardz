const std = @import("std");
const rl = @import("raylib");

const Card = @import("./Card.zig");

const Self = @This();

card_being_dragged: ?*Card = null,
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
    for (self.cards.items) |*card| {
        card.draw(self.card_being_dragged == card);
    }
}

pub fn update(self: *Self) void {
    for (self.cards.items) |*card| {
        card.update(self.card_being_dragged == card);

        if (self.card_being_dragged == null and card.is_dragging_start()) {
            self.card_being_dragged = card;
        }
    }

    if (rl.isMouseButtonReleased(.left)) {
        self.card_being_dragged = null;
    }
}
