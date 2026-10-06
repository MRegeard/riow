const std = @import("std");
const geom = @import("geom.zig");
const Vec3 = geom.Vec3;
const Color = geom.Vec3;
const Ray = @import("Ray.zig");
const objects = @import("objects.zig");
const Hit = objects.Hit;
const rand = @import("rand.zig");

pub const MaterialEnum = enum {
    lambertian,
    metal,
    dielectric,
};

pub const Material = union(MaterialEnum) {
    lambertian: Lambertian,
    metal: Metal,
    dielectric: Dielectric,

    pub fn init(mat: MaterialEnum, albedo: Color, Opts: MaterialOpts) Material {
        return switch (mat) {
            .lambertian => .{ .lambertian = .init(albedo) },
            .metal => .{ .metal = .init(albedo, Opts.metal_fuzz) },
            .dielectric => .{ .dielectric = .init(albedo, Opts.refraction_index) },
        };
    }

    pub fn scatter(self: Material, ray: Ray, hit: Hit) ?Scatter {
        return switch (self) {
            inline else => |m| m.scatter(ray, hit),
        };
    }
};

pub const MaterialOpts = struct {
    metal_fuzz: f64 = 0,
    refraction_index: f64 = 1.0,
};

pub const Scatter = struct {
    attenuation: Color,
    scattered_ray: Ray,
};

pub const Lambertian = struct {
    albedo: Color,

    pub fn init(albedo: Color) Lambertian {
        return .{ .albedo = albedo };
    }

    pub fn scatter(self: Lambertian, ray: Ray, hit: Hit) Scatter {
        _ = ray;
        var scatter_direction = hit.normal.add(rand.randomUnitVector());
        if (scatter_direction.nearZero(1e-8)) {
            scatter_direction = hit.normal;
        }
        return .{
            .attenuation = self.albedo,
            .scattered_ray = .{ .origin = hit.position, .direction = scatter_direction },
        };
    }
};

pub const Metal = struct {
    albedo: Color,
    fuzz: f64 = 0,

    pub fn init(albedo: Color, fuzz: f64) Metal {
        std.debug.assert(fuzz <= 1);
        return .{
            .albedo = albedo,
            .fuzz = fuzz,
        };
    }

    pub fn scatter(self: Metal, ray: Ray, hit: Hit) Scatter {
        var reflected = ray.direction.reflect(hit.normal);
        reflected.normalizeInPlace();
        reflected.addInPlace(rand.randomUnitVector().scale(self.fuzz));
        return .{ .attenuation = self.albedo, .scattered_ray = .{
            .origin = hit.position,
            .direction = reflected,
        } };
    }
};

pub const Dielectric = struct {
    albedo: Color,
    refraction_index: f64 = 1.0,

    pub fn init(albedo: Color, refraction_index: f64) Dielectric {
        return .{
            .albedo = albedo,
            .refraction_index = refraction_index,
        };
    }

    pub fn scatter(self: Dielectric, ray: Ray, hit: Hit) Scatter {
        const ri = if (hit.front_face) (1.0 / self.refraction_index) else self.refraction_index;
        const unit_direction = ray.direction.normalize();

        const cos_theta = @min(unit_direction.neg().dot(hit.normal), 1.0);
        const sin_theta = @sqrt(1.0 - cos_theta*cos_theta);

        const cannot_refract = ri * sin_theta > 1.0;
        var direction: Vec3 = undefined;
        if (cannot_refract or reflectance(cos_theta, ri) > rand.rf64()) {
            direction = unit_direction.reflect(hit.normal);
        } else {
            direction = unit_direction.refract(hit.normal, ri);
        }

        return .{ .attenuation = self.albedo, .scattered_ray = .{
            .direction = direction,
            .origin = hit.position,
        } };
    }

    // Use Schlick's approximation for reflectance.
    fn reflectance(cosine: f64, refraction_index: f64) f64 {
        const r0 = (1 - refraction_index) / (1 + refraction_index);
        const r02 = r0 * r0;
        return r02 + (1 - r02) * std.math.pow(f64, (1 - cosine), 5);
    }
};
