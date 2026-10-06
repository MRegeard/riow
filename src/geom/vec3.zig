const std = @import("std");

pub const Vec3 = @This();

x: f64,
y: f64,
z: f64,

pub fn zeroes() Vec3 {
    return .{ .x = 0, .y = 0, .z = 0 };
}

pub fn init(x: f64, y: f64, z: f64) Vec3 {
    return .{ .x = x, .y = y, .z = z };
}

pub fn neg(v: Vec3) Vec3 {
    return .{ .x = -v.x, .y = -v.y, .z = -v.z };
}

pub fn negInPlace(v: *Vec3) void {
    v.x = -v.x;
    v.y = -v.y;
    v.z = -v.z;
}

pub fn add(self: Vec3, v: Vec3) Vec3 {
    return .{ .x = self.x + v.x, .y = self.y + v.y, .z = self.z + v.z };
}

pub fn addInPlace(self: *Vec3, v: Vec3) void {
    self.x += v.x;
    self.y += v.y;
    self.z += v.z;
}

pub fn sub(self: Vec3, v: Vec3) Vec3 {
    return self.add(v.neg());
}

pub fn subInPlace(self: *Vec3, v: Vec3) void {
    self.addInPlace(v.neg());
}

pub fn scale(self: Vec3, factor: f64) Vec3 {
    return .{
        .x = self.x * factor,
        .y = self.y * factor,
        .z = self.z * factor,
    };
}

pub fn scaleInPlace(self: *Vec3, factor: f64) void {
    self.x *= factor;
    self.y *= factor;
    self.z *= factor;
}

pub fn mag(self: Vec3) f64 {
    return @sqrt(self.magSquare());
}

pub fn magSquare(self: Vec3) f64 {
    return self.dot(self);
}

pub fn dot(self: Vec3, v: Vec3) f64 {
    return @mulAdd(f64, self.x, v.x, @mulAdd(f64, self.y, v.y, self.z * v.z));
}

pub fn eql(self: Vec3, v: Vec3) bool {
    return std.meta.eql(self, v);
}

pub fn splat(f: f64) Vec3 {
    return .{ .x = f, .y = f, .z = f };
}

pub fn cross(self: Vec3, v: Vec3) Vec3 {
    return .{
        .x = self.y * v.z - self.z * v.y,
        .y = self.z * v.x - self.x * v.z,
        .z = self.x * v.y - self.y * v.x,
    };
}

pub fn crossInPlace(self: *Vec3, v: Vec3) void {
    self.* = self.cross(v);
}

pub fn normalize(self: Vec3) Vec3 {
    const mag_square = self.magSquare();
    if (mag_square == 0) return self;
    return self.scale(1 / self.mag());
}

pub fn normalizeInPlace(self: *Vec3) void {
    self.* = self.normalize();
}

pub fn isUnit(self: Vec3, tol: f64) bool {
    return std.math.approxEqAbs(f64, self.magSquare(), 1, tol);
}

pub fn clamp(self: Vec3, min: Vec3, max: Vec3) Vec3 {
    return .{
        .x = std.math.clamp(self.x, min.x, max.x),
        .y = std.math.clamp(self.y, min.y, max.y),
        .z = std.math.clamp(self.z, min.z, max.z),
    };
}

pub fn clampInPlace(self: *Vec3, min: Vec3, max: Vec3) void {
    self.* = self.clamp(min, max);
}

pub fn clampf64(self: Vec3, min: f64, max: f64) Vec3 {
    return .{
        .x = std.math.clamp(self.x, min, max),
        .y = std.math.clamp(self.y, min, max),
        .z = std.math.clamp(self.z, min, max),
    };
}

pub fn clampf64InPlace(self: *Vec3, min: f64, max: f64) void {
    self.* = self.clampf64(min, max);
}

pub fn nearZero(self: Vec3, tol: f64) bool {
    return @abs(self.x) < tol and @abs(self.y) < tol and @abs(self.z) < tol;
}

pub fn reflect(self: Vec3, normal: Vec3) Vec3 {
    return self.sub(normal.scale(2*self.dot(normal)));
}

pub fn mulComps(self: Vec3, other: Vec3) Vec3 {
    return .{
        .x = self.x * other.x,
        .y = self.y * other.y,
        .z = self.z * other.z,
    };
}

pub fn mulCompsInPlace(self: *Vec3, other: Vec3) void {
    self.* = self.mulComps(other);
}

pub fn refract(self: Vec3, normal: Vec3, relative_index: f64) Vec3 {
    const cos_theta = @min(self.neg().dot(normal), 1.0);
    const out_perp = self.add(normal.scale(cos_theta)).scale(relative_index);
    const out_parallel = normal.scale(-@sqrt(@abs(1.0 - out_perp.magSquare())));
    return out_perp.add(out_parallel);
}
