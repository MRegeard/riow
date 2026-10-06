const std = @import("std");

const Ray = @import("Ray.zig");
const objects = @import("objects.zig");
const Object = objects.Object;
const hitAll = objects.hitAll;
const geom = @import("geom.zig");
const Vec3 = geom.Vec3;
const Point3 = geom.Point3;
const Color = Vec3;
const Range = @import("Range.zig");
const rand = @import("rand.zig");

pub const Camera = @This();

aspect_ratio: f64,
image_width: u32,
samples_per_pixel: u32,
image_height: u32,
pixel00_loc: Point3,
pixel_delta_u: Vec3,
pixel_delta_v: Vec3,
camera_center: Point3,
pixel_samples_scale: f64,
max_depth: u32,

pub fn init(aspect_ratio: f64, image_width: u32, samples_per_pixel: u32, max_depth: u32) Camera {
    const image_width_f64: f64 = @floatFromInt(image_width);

    const image_h_f64: f64 = image_width / aspect_ratio;
    const image_height: comptime_int = if (image_h_f64 < 1) 1 else @intFromFloat(image_h_f64);
    const image_height_f64: f64 = @floatFromInt(image_height);

    // Camera
    const focal_length: f64 = 1.0;
    const viewport_height: f64 = 2.0;
    const viewport_width: f64 = viewport_height * (image_width_f64 / image_height_f64);
    const camera_center: Point3 = .zeroes();

    // Calculate the horizontal and vertical vector across the viewport edges.
    const viewport_u: Vec3 = .init(viewport_width, 0, 0);
    const viewport_v: Vec3 = .init(0, -viewport_height, 0);

    // Calculate associated delta vectors from pixel to pixel.
    const pixel_delta_u: Vec3 = viewport_u.scale(1 / image_width_f64);
    const pixel_delta_v: Vec3 = viewport_v.scale(1 / image_height_f64);

    // Calculate location of the upper left pixel.
    const viewport_upper_left = blk: {
        const viewport_u_half = viewport_u.scale(0.5);
        const viewport_v_half = viewport_v.scale(0.5);
        const focal_length_vec: Vec3 = .init(0, 0, focal_length);
        const res = camera_center.sub(focal_length_vec).sub(viewport_u_half).sub(viewport_v_half);
        break :blk res;
    };
    const pixel00_loc = viewport_upper_left.add(pixel_delta_u.add(pixel_delta_v).scale(0.5));

    const pixel_samples_scale: f64 = 1.0 / @as(f64, @floatFromInt(samples_per_pixel));
    return .{
        .aspect_ratio = aspect_ratio,
        .image_width = image_width,
        .samples_per_pixel = samples_per_pixel,
        .image_height = image_height,
        .pixel00_loc = pixel00_loc,
        .pixel_delta_u = pixel_delta_u,
        .pixel_delta_v = pixel_delta_v,
        .camera_center = camera_center,
        .pixel_samples_scale = pixel_samples_scale,
        .max_depth = max_depth,
    };
}

pub fn render(self: Camera, fwriter: *std.Io.Writer, progress: std.Progress.Node, world: []Object) !void {
    try fwriter.print("P3\n{d} {d}\n255\n", .{ self.image_width, self.image_height });

    for (0..self.image_height) |j| {
        progress.completeOne();
        for (0..self.image_width) |i| {
            var pixel_color: Color = .splat(0);
            for (0..self.samples_per_pixel) |_| {
                const ray: Ray = self.getRay(@floatFromInt(i), @floatFromInt(j));
                pixel_color.addInPlace(rayColor(ray, self.max_depth, world));
            }
            try writeColor(fwriter, pixel_color.scale(self.pixel_samples_scale));
        }
    }
}

fn getRay(self: Camera, i: f64, j: f64) Ray {
    const offset = sampleSquare();
    const pixel_sample = self.pixel00_loc
        .add(self.pixel_delta_u.scale(i + offset.x))
        .add(self.pixel_delta_v.scale(j + offset.y));
    const ray_origin = self.camera_center;
    const ray_direction = pixel_sample.sub(ray_origin);

    return .{ .origin = ray_origin, .direction = ray_direction };
}

fn sampleSquare() Vec3 {
    return .{ .x = rand.rf64() - 0.5, .y = rand.rf64() - 0.5, .z = 0 };
}

fn rayColor(ray: Ray, depth: u32, world: []Object) Color {
    if (depth <= 0) {
        return Color.splat(0);
    }
    if (hitAll(world, ray, Range{ .min = 0.001, .max = std.math.inf(f64) })) |h| {
        if (h.material.scatter(ray, h)) |scatter| {
            return scatter.attenuation.mulComps(rayColor(scatter.scattered_ray, depth - 1, world));
        }
        return Color.zeroes();
    }

    const unit_direction: Vec3 = ray.direction.normalize();
    const a = 0.5 * (unit_direction.y + 1.0);
    return Color.init(1, 1, 1).scale(1 - a).add(Color.init(0.5, 0.7, 1.0).scale(a));
}

fn linearToGamma(linear_component: f64) f64 {
    if (linear_component > 0) {
        return @sqrt(linear_component);
    }
    return 0;
}

fn writeColor(writer: *std.Io.Writer, color: Color) !void {
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
