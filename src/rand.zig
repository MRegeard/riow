const std = @import("std");
const geom = @import("geom.zig");
const Vec3 = geom.Vec3;
const builtin = @import("builtin");

var prng = std.Random.DefaultPrng.init(13);

pub fn rf64() f64 {
    const rand = prng.random();
    return rand.float(f64);
}

pub fn rf64Bounded(min: f64, max: f64) f64 {
    if (builtin.mode == .Debug) {
        std.debug.assert(min < max);
    }
    return min + (max - min) * rf64();
}

pub fn randomVec3() Vec3 {
    return .{
        .x = rf64(),
        .y = rf64(),
        .z = rf64(),
    };
}

pub fn randomVec3Bounded(min: f64, max: f64) Vec3 {
    if (builtin.mode == .Debug) {
        std.debug.assert(min < max);
    }
    return .{
        .x = rf64Bounded(min, max),
        .y = rf64Bounded(min, max),
        .z = rf64Bounded(min, max),
    };
}

pub fn randomUnitVector() Vec3 {
    while (true) {
        const p = randomVec3Bounded(-1, 1);
        const magSq = p.magSquare();
        if (magSq > 1e-160 and magSq <= 1) {
            return p.scale(1 / @sqrt(magSq));
        }
    }
}

pub fn randomOnHemisphere(normal: Vec3) Vec3 {
    const on_unit_sphere = randomUnitVector();
    if (on_unit_sphere.dot(normal) > 0.0) {
        return on_unit_sphere;
    } else {
        return on_unit_sphere.neg();
    }
}
