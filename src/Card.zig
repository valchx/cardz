const std = @import("std");
const rl = @import("raylib");

const Utils = @import("./utils.zig");

const Self = @This();

pub const DEFAULT_CARD_HEIGHT: f32 = 100;

id: Id,
render_texture: ?rl.RenderTexture2D = null,
position: rl.Vector2,
// TODO : Decorelate Card size from screen size.
size: rl.Vector2,
base_rotation: f32 = 0,
rotation: f32 = 0,
sway_rotation: f32 = 0,
sway_target: f32 = 0,
is_dragging: bool = false,

pub fn init(id: Id) !Self {
    const height = DEFAULT_CARD_HEIGHT;
    const width = height_to_width_f32(height);
    const center = rl.Vector2.init(
        @floatFromInt(rl.getScreenWidth()),
        @floatFromInt(rl.getScreenHeight()),
    ).scale(0.5);

    var self = Self{
        .id = id,
        .position = center,
        .size = rl.Vector2.init(width, height),
    };

    try self.update_texture();

    return self;
}

pub fn deinit(self: Self) void {
    if (self.render_texture) |render_texture| {
        rl.unloadRenderTexture(render_texture);
    }
}

const TEXTURE_HEIGHT: i32 = 200;
pub const CARD_CORNER_ROUNDEDNESS = 0.2;

fn update_texture(self: *Self) !void {
    if (self.render_texture) |render_texture| {
        rl.unloadRenderTexture(render_texture);
    }
    self.render_texture = try rl.loadRenderTexture(height_to_width_i32(TEXTURE_HEIGHT), TEXTURE_HEIGHT);

    if (self.render_texture) |tex| {
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
            CARD_CORNER_ROUNDEDNESS,
            0,
            .white,
        );

        // TODO : Maybe use some custom textures ?
        const color: rl.Color = if (self.id.suite.isRed()) .red else .black;

        var gpa = std.heap.GeneralPurposeAllocator(.{}){};
        defer _ = gpa.deinit();
        const alloc = gpa.allocator();

        var rank_c_str = try Utils.cStrFromSlice(self.id.rank.toStr(), alloc);
        defer rank_c_str.deinit();

        const font_size = 60;

        rl.drawText(
            rank_c_str.data,
            @divFloor(tex_width, 2) - 10,
            tex_height - font_size,
            font_size,
            color,
        );

        var suite_c_str = try Utils.cStrFromSlice(self.id.suite.toStr(), alloc);
        defer suite_c_str.deinit();

        rl.drawText(
            suite_c_str.data,
            // TODO : Figure out how to fit it nicely
            @divFloor(tex_width, 2) + 30,
            tex_height - font_size,
            font_size,
            color,
        );
    }
}

pub fn draw(self: Self) void {
    if (self.render_texture) |tex| {
        var pos = self.position;

        if (self.is_dragging) {
            // TODO : Use existing or new texture to get rotation.
            rl.drawRectangleRounded(
                .init(
                    pos.x - self.size.x / 2,
                    pos.y - self.size.y / 2,
                    self.size.x,
                    self.size.y,
                ),
                CARD_CORNER_ROUNDEDNESS,
                0,
                .init(0, 0, 0, 50),
            );

            pos = pos.subtract(.init(10, 10));
        }

        rl.drawTexturePro(
            tex.texture,
            .init(
                0,
                0,
                @floatFromInt(tex.texture.width),
                @floatFromInt(-tex.texture.height),
            ),
            .init(
                pos.x,
                pos.y,
                self.size.x,
                self.size.y,
            ),
            self.size.divide(.init(2, 2)),
            self.rotation,
            .white,
        );

        // TODO : add some kind of build flag.
        // Debug
        if (true) {
            // Center of card
            rl.drawCircle(
                @intFromFloat(self.position.x),
                @intFromFloat(self.position.y),
                5,
                .black,
            );

            // Collision triangles
            const two_triangles = self.get_two_triangles();
            const triangle_1 = two_triangles.triangle_1;
            const triangle_2 = two_triangles.triangle_2;

            rl.drawTriangleLines(
                triangle_1[0],
                triangle_1[1],
                triangle_1[2],
                .red,
            );
            rl.drawTriangleLines(
                triangle_2[0],
                triangle_2[1],
                triangle_2[2],
                .red,
            );
        }
    }
}

fn lerp(a: f32, b: f32, t: f32) f32 {
    return a + (b - a) * t;
}

pub fn update(self: *Self) void {
    const mouse_pos = rl.getMousePosition();
    const mouse_delta = rl.getMouseDelta();
    const delta_time = rl.getFrameTime();

    if (self.is_dragging) {
        self.position = self.position.add(mouse_delta);

        const velocity = mouse_delta.x * 12.0;
        const normalized_sway = velocity * 1.8;

        const sway_max_abs = 25.0;
        const target_sway = @max(-sway_max_abs, @min(sway_max_abs, normalized_sway));

        self.sway_target = target_sway;
        self.sway_rotation = std.math.lerp(
            self.sway_rotation,
            self.sway_target,
            20.0 * delta_time,
        );
    } else if (self.sway_rotation != 0) {
        self.sway_target = 0;
        self.sway_rotation = std.math.lerp(
            self.sway_rotation,
            self.sway_target,
            12.0 * delta_time,
        );
    }
    self.rotation = self.base_rotation + self.sway_rotation;

    const two_triangles = self.get_two_triangles();
    const triangle_1 = two_triangles.triangle_1;
    const triangle_2 = two_triangles.triangle_2;

    const triangle_1_col = rl.checkCollisionPointTriangle(
        mouse_pos,
        triangle_1[0],
        triangle_1[1],
        triangle_1[2],
    );
    const triangle_2_col = rl.checkCollisionPointTriangle(
        mouse_pos,
        triangle_2[0],
        triangle_2[1],
        triangle_2[2],
    );

    const mouse_over_card = triangle_1_col or triangle_2_col;

    if (rl.isMouseButtonPressed(.left) and mouse_over_card) {
        self.is_dragging = true;
    }

    if (rl.isMouseButtonReleased(.left)) {
        self.is_dragging = false;
    }
}

fn get_two_triangles(self: Self) struct { triangle_1: [3]rl.Vector2, triangle_2: [3]rl.Vector2 } {
    // 1. Move corners TO ORIGIN (subtract center)
    var tl = self.position.subtract(self.size.divide(.{ .x = 2, .y = 2 }));
    var tr = tl.add(.{ .x = self.size.x, .y = 0 });
    var br = tl.add(.{ .x = self.size.x, .y = self.size.y });
    var bl = tl.add(.{ .x = 0, .y = self.size.y });

    // 2. Translate TO ORIGIN for rotation
    tl = tl.subtract(self.position);
    tr = tr.subtract(self.position);
    br = br.subtract(self.position);
    bl = bl.subtract(self.position);

    // 3. Rotate around origin (0,0)
    const mat = rl.Matrix.rotateZ(std.math.degreesToRadians(self.rotation));
    tl = tl.transform(mat);
    tr = tr.transform(mat);
    br = br.transform(mat);
    bl = bl.transform(mat);

    // 4. Translate BACK to world position
    tl = tl.add(self.position);
    tr = tr.add(self.position);
    br = br.add(self.position);
    bl = bl.add(self.position);

    return .{ .triangle_1 = .{ tl, tr, br }, .triangle_2 = .{ br, bl, tl } };
}

pub fn height_to_width_f32(height: f32) f32 {
    return (height * 5) / 7;
}

fn height_to_width_i32(height: i32) i32 {
    return @divFloor(height * 5, 7);
}

pub const Suite = enum {
    spades,
    hearts,
    clubs,
    diamonds,

    pub fn isRed(self: Suite) bool {
        return switch (self) {
            Suite.hearts, Suite.diamonds => true,
            else => false,
        };
    }

    const symbol_index = blk: {
        // TODO : Can get 13 from enum size ?
        var strings: [4][]const u8 = undefined;
        for (std.meta.fields(Suite), 0..) |suite_field, i| {
            const suite: Suite = @enumFromInt(suite_field.value);
            strings[i] = switch (suite) {
                Suite.spades => "S",
                Suite.hearts => "H",
                Suite.clubs => "C",
                Suite.diamonds => "D",
            };
        }
        break :blk strings;
    };

    pub fn toStr(self: Suite) []const u8 {
        return symbol_index[@intFromEnum(self)];
    }
};

pub const Rank = enum {
    n2,
    n3,
    n4,
    n5,
    n6,
    n7,
    n8,
    n9,
    n10,
    jack,
    queen,
    king,
    ace,

    pub fn isFace(self: Rank) bool {
        return switch (self) {
            Rank.jack...Rank.king => true,
            _ => false,
        };
    }

    pub fn blackJackValue(self: Rank) []const i32 {
        return switch (self) {
            Rank.n2...Rank.n9 => .{self + 2},
            Rank.n10...Rank.king => .{10},
            // TODO : handle soft hands. Maybe return two options.
            Rank.ace => .{ 1, 11 },
        };
    }

    const symbol_index = blk: {
        // TODO : Can get 13 from enum size ?
        var strings: [13][]const u8 = undefined;
        for (std.meta.fields(Rank), 0..) |rank_field, i| {
            const rank: Rank = @enumFromInt(rank_field.value);
            strings[i] = switch (rank) {
                else => std.fmt.comptimePrint("{}", .{@intFromEnum(rank)}),
                Rank.jack => "J",
                Rank.queen => "Q",
                Rank.king => "K",
                Rank.ace => "A",
            };
        }
        break :blk strings;
    };

    pub fn toStr(self: Rank) []const u8 {
        return symbol_index[@intFromEnum(self)];
    }
};

pub const Id = struct {
    suite: Suite,
    rank: Rank,
};
