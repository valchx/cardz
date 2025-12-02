const rl = @import("raylib");

const DropSlot = @import("DropSlot.zig");
const Context = @import("Context.zig");

const Self = @This();

rect: rl.Rectangle,

pub fn init(dimentions: rl.Vector2) Self {
    return .{
        .rect = .init(0, 0, dimentions.x, dimentions.y),
    };
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
