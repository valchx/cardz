const rl = @import("raylib");

const Card = @import("Card.zig");

const Self = @This();

content: ?*const Card = null,
rect: rl.Rectangle,

pub fn init(rect: rl.Rectangle) Self {
    return .{ .rect = rect };
}

pub fn draw(self: Self) void {
    rl.drawRectangleRounded(
        self.rect,
        Card.CARD_CORNER_ROUNDEDNESS,
        0,
        .white,
    );
}
