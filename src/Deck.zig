const std = @import("std");
const rl = @import("raylib");

const Card = @import("Card.zig");

const Self = @This();

cards: std.ArrayList(Card),
_cards_arena: std.heap.ArenaAllocator,
back_render_texture: ?rl.RenderTexture2D = null,

pub fn init() !Self {
    var cards_arena = std.heap.ArenaAllocator.init(std.heap.page_allocator);

    const cards = try std.ArrayList(Card).initCapacity(
        cards_arena.allocator(),
        0,
    );

    var self = Self{
        .cards = cards,
        ._cards_arena = cards_arena,
    };

    try self.update_texture();

    return self;
}

pub fn deinit(self: *Self) void {
    self._cards_arena.deinit();

    if (self.back_render_texture) |render_texture| {
        rl.unloadRenderTexture(render_texture);
    }
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

fn update_texture(self: *Self) !void {
    if (self.back_render_texture) |render_texture| {
        rl.unloadRenderTexture(render_texture);
    }

    self.back_render_texture = try rl.loadRenderTexture(
        Card.height_to_width_i32(Card.TEXTURE_HEIGHT),
        Card.TEXTURE_HEIGHT,
    );

    if (self.back_render_texture) |tex| {
        const tex_width = tex.texture.width;
        const tex_height = tex.texture.height;

        rl.beginTextureMode(tex);
        defer rl.endTextureMode();

        var background = rl.Color.white;
        background.a = 0;
        rl.clearBackground(background);

        rl.drawRectangleRounded(
            .init(
                0,
                0,
                @floatFromInt(tex_width),
                @floatFromInt(tex_height),
            ),
            Card.CARD_CORNER_ROUNDEDNESS,
            0,
            .white,
        );

        const h_lines = 20;
        for (1..h_lines) |i| {
            const line_height: c_int = @divFloor(
                @as(
                    c_int,
                    @intCast(i),
                ) * tex_height,
                h_lines,
            );

            const thickness = 4;
            rl.drawLineEx(
                .init(0, @floatFromInt(line_height)),
                .init(@floatFromInt(tex_width), @floatFromInt(line_height)),
                thickness,
                .blue,
            );
        }

        const v_lines = 20;
        for (1..v_lines) |i| {
            const line_width: c_int = @divFloor(
                @as(
                    c_int,
                    @intCast(i),
                ) * tex_height,
                v_lines,
            );

            const thickness = 4;
            rl.drawLineEx(
                .init(@floatFromInt(line_width), 0),
                .init(@floatFromInt(line_width), @floatFromInt(tex_height)),
                thickness,
                .blue,
            );
        }
    }
}
