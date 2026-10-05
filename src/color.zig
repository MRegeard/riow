const std = @import("std");
const geom = @import("geom.zig");
const Ray = @import("Ray.zig");
const Vec3 = geom.Vec3;
const Point3 = Vec3;
const objects = @import("objects.zig");
const Hittable = objects.Hittable;
const hitAll = objects.hitAll;
const Range = @import("Range.zig");

pub const Color = Vec3;


//TODO: use std.fmt.Alt instead and call format.
pub fn writeColor(writer: *std.Io.Writer, color: Color) !void {
    const rbyte: u8 = @intFromFloat(255.999 * color.x);
    const gbyte: u8 = @intFromFloat(255.999 * color.y);
    const bbyte: u8 = @intFromFloat(255.999 * color.z);

    try writer.print("{d} {d} {d}\n", .{ rbyte, gbyte, bbyte });
}

pub fn rayColor(ray: Ray, world: []Hittable) Color {
    if(hitAll(world, ray, Range{.min = 0, .max = std.math.inf(f64)})) |h| {
        return h.normal.add(Color.init(1, 1, 1)).scale(0.5);
    }

    const unit_direction: Vec3 = ray.direction.normalize();
    const a = 0.5*(unit_direction.y + 1.0);
    return Color.init(1, 1, 1).scale(1 - a).add(Color.init(0.5, 0.7, 1.0).scale(a));
}
