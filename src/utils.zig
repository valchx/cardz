const std = @import("std");

pub fn cStrFromSlice(slice: []const u8, alloc: std.mem.Allocator) !struct {
    const Self = @This();

    buf: []u8,
    data: [:0]const u8,
    _alloc: std.mem.Allocator,

    pub fn deinit(self: *Self) void {
        self._alloc.free(self.buf);
    }
} {
    const buffer = try alloc.alloc(u8, slice.len + 1);
    errdefer alloc.free(buffer);

    std.mem.copyForwards(u8, buffer, slice);
    buffer[slice.len] = 0;

    const c_str: [*:0]const u8 = @ptrCast(buffer.ptr);

    return .{
        .buf = buffer,
        .data = std.mem.span(c_str),
        ._alloc = alloc,
    };
}
