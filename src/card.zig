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
    }
}

pub fn update(self: *Self) void {
    if (self.dragging_coords) |_| {
        const mouse_delta = rl.getMouseDelta();

        self.position = self.position.add(mouse_delta);
    }

    // TODO : Colision on rotated rects
    const origin_point = self.position.subtract(self.size.divide(.init(2, 2)));
    const bounds: rl.Rectangle = .init(origin_point.x, origin_point.y, self.size.x, self.size.y);
    const mouse_over_card = rl.checkCollisionPointRec(rl.getMousePosition(), bounds);

    if (rl.isMouseButtonPressed(.left) and mouse_over_card) {
        self.dragging_coords = rl.getMousePosition();
    }

    if (rl.isMouseButtonReleased(.left)) {
        self.dragging_coords = null;
    }
}

fn height_to_width_f32(height: f32) f32 {
    return height * 7 / 5;
}

fn height_to_width_i32(height: i32) i32 {
    return @divFloor(height * 7, 5);
}
