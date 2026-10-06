const std = @import("std");
const builtin = @import("builtin");

const geom = @import("geom.zig");
const Point3 = geom.Point3;
const Vec3 = geom.Vec3;
const Ray = @import("Ray.zig");
const Range = @import("Range.zig");

pub fn hitAll(obj_list: []Object, ray: Ray, ray_range: Range) ?Hit {
    var closest = ray_range.max;
    var hit_record: ?Hit = null;
    for (obj_list) |obj| {
        if (obj.hit(ray, Range{ .min = ray_range.min, .max = closest })) |h| {
            closest = h.t;
            hit_record = h;
        }
    }
    return hit_record;
}

pub const ObjectEnum = enum {
    sphere,
};

pub const Object = union(ObjectEnum) {
    const Self = @This();

    sphere: Sphere,

    pub fn hit(self: Self, ray: Ray, ray_range: Range) ?Hit {
        return switch (self) {
            .sphere => |s| s.hit(ray, ray_range),
        };
    }
};

pub const Hit = struct {
    position: Point3,
    normal: Vec3,
    t: f64,
    front_face: bool,

    pub fn init(ray: Ray, t: f64, position: Vec3, normal: Vec3) Hit {
        if (builtin.mode == .Debug) {
            std.debug.assert(normal.isUnit(1e-8));
        }
        const front_face = ray.direction.dot(normal) < 0;
        return .{
            .position = position,
            .t = t,
            .normal = if (front_face) normal else normal.neg(),
            .front_face = front_face,
        };
    }
};

pub const Sphere = struct {
    const Self = @This();

    center: Point3,
    radius: f64,

    pub fn init(center: Point3, radius: f64) Self {
        std.debug.assert(radius >= 0);
        return .{ .center = center, .radius = radius };
    }

    pub fn hit(self: Self, ray: Ray, ray_range: Range) ?Hit {
        const oc: Vec3 = self.center.sub(ray.origin);
        const a = ray.direction.magSquare();
        const h = ray.direction.dot(oc);
        const c = oc.magSquare() - self.radius * self.radius;

        const discriminant = h * h - a * c;
        if (discriminant < 0) {
            return null;
        }

        const sqrtd = @sqrt(discriminant);
        var root = (h - sqrtd) / a;
        if (!ray_range.surrounds(root)) {
            root = (h + sqrtd) / a;
            if (!ray_range.surrounds(root)) {
                return null;
            }
        }

        const pos = ray.at(root);
        const normal = (pos.sub(self.center)).scale(1 / self.radius);
        return Hit.init(ray, root, pos, normal);
    }
};
