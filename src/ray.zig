const geom = @import("geom.zig");
const Vec3 = geom.Vec3;
const Point3 = geom.Point3;

pub const Ray = @This();

origin: Point3,
direction: Vec3,

pub fn at(self: *const Ray, t: f64) Point3 {
    return self.origin.add(self.direction.scale(t));
}


