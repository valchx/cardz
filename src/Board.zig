const std = @import("std");
const rl = @import("raylib");

const DropSlot = @import("DropSlot.zig");
const Context = @import("Context.zig");
const Card = @import("Card.zig");

const Self = @This();

rect: rl.Rectangle,
drop_slots: std.ArrayList(DropSlot),
_drop_slots_alloc: std.heap.ArenaAllocator,

pub fn init(dimentions: rl.Vector2) !Self {
    var arena = std.heap.ArenaAllocator.init(std.heap.page_allocator);

    return .{
        .rect = .init(0, 0, dimentions.x, dimentions.y),
        .drop_slots = try .initCapacity(arena.allocator(), 0),
        ._drop_slots_alloc = arena,
    };
}

pub fn deinit(self: *Self) void {
    self._drop_slots_alloc.deinit();
}

pub fn draw(self: Self, ctx: *const Context) void {
    const origin = rl.Vector2.init(
        self.rect.x,
        self.rect.y,
    ).multiply(.init(
        ctx.world_to_screen_scale,
        ctx.world_to_screen_scale,
    ));
    const dimentions = rl.Vector2.init(
        self.rect.width,
        self.rect.height,
    ).multiply(.init(
        ctx.world_to_screen_scale,
        ctx.world_to_screen_scale,
    ));

    rl.drawRectangle(
        @intFromFloat(origin.x),
        @intFromFloat(origin.y),
        @intFromFloat(dimentions.x),
        @intFromFloat(dimentions.y),
        .dark_green,
    );

    for (self.drop_slots.items) |drop_slot| {
        drop_slot.draw();
    }
}

pub fn addDropZone(self: *Self, position: rl.Vector2) !void {
    try self.drop_slots.append(
        self._drop_slots_alloc.allocator(),
        .init(
            .init(
                position.x,
                position.y,
                Card.height_to_width_f32(Card.DEFAULT_CARD_HEIGHT),
                Card.DEFAULT_CARD_HEIGHT,
            ),
        ),
    );
}
