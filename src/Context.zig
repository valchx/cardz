const rl = @import("raylib");

/// World dimentions should be in a real unit like "centimeters".
/// This will help handle different resolutions and zooming.
/// For instance, if `worldToScreenScale` is `0.25`, a square of dimentions
/// 100x100 would be displayed as a 25x25 pixel square.
world_to_screen_scale: f32 = 1,
screen_size: rl.Vector2,
