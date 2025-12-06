const std = @import("std");
const rl = @import("raylib");

const Card = @import("Card.zig");

const Self = @This();

content: ?* Card = null,
rect: rl.Rectangle,

pub fn init(rect: rl.Rectangle) Self {
    return .{ .rect = rect };
}

const PADDING = 5;
pub fn draw(self: Self) void {
    rl.drawRectangleRoundedLinesEx(
        .init(
            self.rect.x - PADDING,
            self.rect.y - PADDING,
            self.rect.width + (2 * PADDING),
            self.rect.height + (2 * PADDING),
        ),
        Card.CARD_CORNER_ROUNDEDNESS,
        0,
        2,
        .white,
    );
}

pub fn isPullingCard(self: Self, card: Card) bool {
    if (self.content != null) {
        return false;
    }

    if (rl.checkCollisionPointRec(card.position, self.rect)) {
        return true;
    }

    return false;
}
