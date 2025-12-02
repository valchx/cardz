const std = @import("std");
const rl = @import("raylib");

const Utils = @import("./utils.zig");

const Self = @This();

id: Id,
render_texture: rl.RenderTexture2D,
position: rl.Vector2,
// TODO : Decorelate Card size from screen size.
size: rl.Vector2,
base_rotation: f32 = 0,
rotation: f32 = 0,
sway_rotation: f32 = 0,
sway_target: f32 = 0,
is_dragging: bool = false,
debug: bool = false,

pub fn init(id: Id) !Self {
    const height = 100;
    const width = height_to_width_f32(height);
    const center = rl.Vector2.init(
        @floatFromInt(rl.getScreenWidth()),
        @floatFromInt(rl.getScreenHeight()),
    ).divide(rl.Vector2.init(2, 2));

    const texture_height: i32 = 200;
    const rt = try rl.loadRenderTexture(height_to_width_i32(texture_height), texture_height);

    const self = Self{
        .id = id,
        .position = center,
        .size = rl.Vector2.init(height, width),
        .render_texture = rt,
    };

    try self.update_texture();

    return self;
}

pub fn deinit(self: Self) void {
    rl.unloadRenderTexture(self.render_texture);
}

pub const CARD_CORNER_ROUNDEDNESS = 0.2;

fn update_texture(self: Self) !void {
    const tex = self.render_texture;

    rl.beginTextureMode(tex);
    defer rl.endTextureMode();

    var background = rl.Color.white;
    background.a = 0;
    rl.clearBackground(background);

    rl.drawRectangleRounded(
        .init(
            0,
            0,
            @floatFromInt(tex.texture.width),
            @floatFromInt(tex.texture.height),
        ),
        CARD_CORNER_ROUNDEDNESS,
        0,
        .white,
    );

    const color: rl.Color = if (self.id.suite.isRed()) .red else .black;

    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    defer _ = gpa.deinit();
    const alloc = gpa.allocator();

    var rank_c_str = try Utils.cStrFromSlice(self.id.rank.toStr(), alloc);
    defer rank_c_str.deinit();

    rl.drawText(
        rank_c_str.data,
        @divFloor(tex.texture.width, 2) - 10,
        @divFloor(tex.texture.height, 2),
        100,
        color,
    );

    var suite_c_str = try Utils.cStrFromSlice(self.id.suite.toStr(), alloc);
    defer suite_c_str.deinit();

    rl.drawText(
        suite_c_str.data,
        // TODO : Figure out how to fit it nicely
        @divFloor(tex.texture.width, 2) + 60,
        @divFloor(tex.texture.height, 2),
        100,
        color,
    );
}

pub fn draw(self: Self) void {
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
        self.render_texture.texture,
        .init(
            0,
            0,
            @floatFromInt(self.render_texture.texture.width),
            @floatFromInt(-self.render_texture.texture.height),
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

    if (self.debug) {
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

fn height_to_width_f32(height: f32) f32 {
    return height * 7 / 5;
}

fn height_to_width_i32(height: i32) i32 {
    return @divFloor(height * 7, 5);
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
