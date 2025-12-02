const std = @import("std");
const rl = @import("raylib");

const DropSlot = @import("DropSlot.zig");
const Context = @import("Context.zig");

const Self = @This();

rect: rl.Rectangle,
drop_slots: std.ArrayList(DropSlot),
_drop_slots_alloc: std.mem.Allocator,

pub fn init(dimentions: rl.Vector2) !Self {
    var deck_arena = std.heap.ArenaAllocator.init(std.heap.page_allocator);
    const drop_slots_alloc = deck_arena.allocator();

    return .{
        .rect = .init(0, 0, dimentions.x, dimentions.y),
        .drop_slots = try .initCapacity(drop_slots_alloc, 0),
        ._drop_slots_alloc = drop_slots_alloc,
    };
}

pub fn deinit(self: *Self) void {
    self.drop_slots.clearAndFree(self._drop_slots_alloc);
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
}
