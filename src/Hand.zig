const std = @import("std");
const rl = @import("raylib");

const Card = @import("./Card.zig");
const DropZone = @import("./DropZone.zig");

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

pub fn draw(
    self: Self,
    back_render_texture: *const ?rl.RenderTexture,
) void {
    for (self.cards.items) |*card| {
        const is_being_dragged = self.card_being_dragged == card;
        card.draw(is_being_dragged, back_render_texture);
    }
}

pub fn update(self: *Self, drop_zones: []DropZone) void {
    for (self.cards.items) |*card| {
        card.update(self.card_being_dragged == card);

        if (self.card_being_dragged == null and card.is_dragging_start()) {
            self.card_being_dragged = card;
        }

        for (drop_zones) |*drop_zone| {
            if (rl.isMouseButtonReleased(.left) and drop_zone.isPullingCard(card.*)) {
                drop_zone.content = card;
                card.position = .init(
                    drop_zone.rect.x + (drop_zone.rect.width / 2),
                    drop_zone.rect.y + (drop_zone.rect.height / 2),
                );
            }

            if (self.card_being_dragged == card and card.is_dragging_start()) {
                drop_zone.content = null;
            }
        }
    }

    if (rl.isMouseButtonReleased(.left)) {
        self.card_being_dragged = null;
    }
}
