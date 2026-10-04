const std = @import("std");
const geom = @import("geom.zig");
const Ray = @import("ray.zig");
const Vec3 = geom.Vec3;
const Point3 = Vec3;
pub const Color = Vec3;

//TODO: use std.fmt.Alt instead and call format.
pub fn writeColor(writer: *std.Io.Writer, color: *const Color) !void {
    const rbyte: u8 = @intFromFloat(255.999 * color.x);
    const gbyte: u8 = @intFromFloat(255.999 * color.y);
    const bbyte: u8 = @intFromFloat(255.999 * color.z);

    try writer.print("{d} {d} {d}\n", .{ rbyte, gbyte, bbyte });
}

pub fn hit_sphere(center: Point3, radius: f64, ray: *const Ray) bool {
    const oc: Vec3 = center.sub(ray.origin);
    const a = ray.direction.dot(ray.direction);
    const b = -2.0 * ray.direction.dot(oc);
    const c = oc.dot(oc) - radius * radius;
    const discriminant = b * b - 4 * a * c;
    return discriminant >= 0;
}

pub fn rayColor(ray: *const Ray) Color {
    if (hit_sphere(Point3.init(0, 0, -1), 0.5, ray)) {
        return Color.init(1, 0, 0);
    }
    const unit_direction: Vec3 = ray.direction.normalize();
    const a = 0.5 * (unit_direction.y + 1.0);
    return Color.init(1, 1, 1).scale(1.0 - a).add(Color.init(0.5, 0.7, 1).scale(a));
}
