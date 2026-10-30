const std = @import("std");
const Io = std.Io;
const Vec3 = @import("geom.zig").Vec3;
const Color = Vec3;

fn linearToGamma(linear_component: f64) f64 {
    if (linear_component > 0) {
        return @sqrt(linear_component);
    }
    return 0;
}

pub fn writeColor(writer: *Io.Writer, color: Color) !void {
    const gamma_color: Color = .{
        .x = linearToGamma(color.x),
        .y = linearToGamma(color.y),
        .z = linearToGamma(color.z),
    };
    const color_clamp = gamma_color.clampf64(0.000, 0.999);
    const rbyte: u8 = @intFromFloat(256 * color_clamp.x);
    const gbyte: u8 = @intFromFloat(256 * color_clamp.y);
    const bbyte: u8 = @intFromFloat(256 * color_clamp.z);

    try writer.print("{d} {d} {d}\n", .{ rbyte, gbyte, bbyte });
}
