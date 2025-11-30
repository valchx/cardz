const std = @import("std");
const rl = @import("raylib");

const Self = @This();

position: rl.Vector2,
size: rl.Vector2,
rotation: f32 = 0,
render_texture: rl.RenderTexture2D,
dragging_coords: ?rl.Vector2 = null, // Grab coordinate
debug: bool = false,

pub fn init(screen_size: rl.Vector2) rl.RaylibError!Self {
    const height = 200;
    const width = height_to_width_f32(height);
    const center = screen_size.divide(rl.Vector2.init(2, 2));

    const texture_height: i32 = 200;
    const rt = try rl.loadRenderTexture(height_to_width_i32(texture_height), texture_height);

    const self = Self{
        .position = center,
        .size = rl.Vector2.init(height, width),
        .render_texture = rt,
    };

    self.update_texture();

    return self;
}

pub fn deinit(self: Self) void {
    rl.unloadRenderTexture(self.render_texture);
}

fn update_texture(self: Self) void {
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
        0.2,
        0,
        .white,
    );
}

pub fn draw(self: Self) void {
    rl.drawTexturePro(
        self.render_texture.texture,
        .init(
            0,
            0,
            @floatFromInt(self.render_texture.texture.width),
            @floatFromInt(self.render_texture.texture.height),
        ),
        .init(self.position.x, self.position.y, self.size.x, self.size.y),
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

pub fn update(self: *Self) void {
    const mouse_pos = rl.getMousePosition();

    if (self.dragging_coords) |_| {
        const mouse_delta = rl.getMouseDelta();

        self.position = self.position.add(mouse_delta);
    }

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
        self.dragging_coords = rl.getMousePosition();
    }

    if (rl.isMouseButtonReleased(.left)) {
        self.dragging_coords = null;
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

    return .{ 
        .triangle_1 = .{ tl, tr, br }, 
        .triangle_2 = .{ br, bl, tl } 
    };
}

fn height_to_width_f32(height: f32) f32 {
    return height * 7 / 5;
}

fn height_to_width_i32(height: i32) i32 {
    return @divFloor(height * 7, 5);
}
