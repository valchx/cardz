const std = @import("std");
const rl = @import("raylib");

const DropZone = @import("DropZone.zig");
const Context = @import("Context.zig");
const Card = @import("Card.zig");

const Self = @This();

bounds: rl.Rectangle,
drop_zones: std.ArrayList(DropZone),
_drop_zones_alloc: std.heap.ArenaAllocator,

pub fn init(dimentions: rl.Vector2) !Self {
    var arena = std.heap.ArenaAllocator.init(std.heap.page_allocator);

    return .{
        .bounds = .init(0, 0, dimentions.x, dimentions.y),
        .drop_zones = try .initCapacity(arena.allocator(), 0),
        ._drop_zones_alloc = arena,
    };
}

pub fn deinit(self: *Self) void {
    self._drop_zones_alloc.deinit();
}

pub fn draw(self: Self, ctx: *const Context) void {
    const origin = rl.Vector2.init(
        self.bounds.x,
        self.bounds.y,
    ).scale(ctx.world_to_screen_scale);

    const dimentions = rl.Vector2.init(
        self.bounds.width,
        self.bounds.height,
    ).scale(ctx.world_to_screen_scale);

    rl.drawRectangle(
        @intFromFloat(origin.x),
        @intFromFloat(origin.y),
        @intFromFloat(dimentions.x),
        @intFromFloat(dimentions.y),
        .dark_green,
    );

    for (self.drop_zones.items) |drop_slot| {
        drop_slot.draw();
    }
}

pub fn addDropZone(self: *Self, position: rl.Vector2) !void {
    try self.drop_zones.append(
        self._drop_zones_alloc.allocator(),
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
