const std = @import("std");
const builtin = @import("builtin");
const Io = std.Io;

const riowlib = @import("riowlib");
const geom = riowlib.geom;
const Vec3 = geom.Vec3;
const Point3 = geom.Point3;
const Color = Vec3;
const Ray = riowlib.Ray;
const objects = riowlib.objects;
const Object = objects.Object;
const Hit = objects.Hit;
const Camera = riowlib.Camera;
const material = riowlib.material;
const color = riowlib.color;
const rand = riowlib.rand;

//// Material
//const material_ground = material.Material.init(.lambertian, Color.init(0.8, 0.8, 0.0), .{});
//const material_center = material.Material.init(.lambertian, Color.init(0.1, 0.2, 0.5), .{});
////const material_left = material.Material.init(.metal, Color.init(0.8, 0.8, 0.8), .{ .metal_fuzz = 0.3 });
//const material_left = material.Material.init(.dielectric, Color.init(1.0, 1.0, 1.0), .{ .refraction_index = 1.5 });
//const material_bubble = material.Material.init(.dielectric, Color.init(1.0, 1.0, 1.0), .{ .refraction_index = 1.0 / 1.5 });
//const material_right = material.Material.init(.metal, Color.init(0.8, 0.6, 0.2), .{ .metal_fuzz = 1.0 });
//
//// Objects
//const sphere_ground = Object{ .sphere = .init(Point3.init(0.0, -100.5, -1.0), 100, @constCast(&material_ground)) };
//const sphere_center = Object{ .sphere = .init(Point3.init(0.0, 0.0, -1.2), 0.5, @constCast(&material_center)) };
//const sphere_left = Object{ .sphere = .init(Point3.init(-1.0, 0.0, -1.0), 0.5, @constCast(&material_left)) };
//const sphere_bubble = Object{ .sphere = .init(Point3.init(-1.0, 0.0, -1.0), 0.4, @constCast(&material_bubble)) };
//const sphere_right = Object{ .sphere = .init(Point3.init(1.0, 0, -1.0), 0.5, @constCast(&material_right)) };
//
//// World
//const world: [5]Object = .{ sphere_ground, sphere_left, sphere_center, sphere_bubble, sphere_right };

const ground_material = material.Material.init(.lambertian, .init(0.5, 0.5, 0.5), .{});
const sphere_ground = Object{ .sphere = .init(.init(0, -1000, 0), 1000, ground_material) };

// Camera
const aspect_ratio: f64 = 16.0 / 9.0;
const image_width = 1200;
const samples_per_pixel = 500;
const max_depth = 50;
const vfov = 20;
const lookfrom: Point3 = .init(13, 2, 3);
const lookat: Point3 = .init(0, 0, 0);
const vup: Vec3 = .init(0, 1, 0);
const defocus_angle = 0.6;
const focus_dist = 10.0;

const camera: Camera = .init(aspect_ratio, image_width, samples_per_pixel, max_depth, vfov, lookfrom, lookat, vup, defocus_angle, focus_dist);

// Thread
const thread_number = 8;
const pixel_number = camera.image_width * camera.image_height;

fn getLineNumber(idx: usize, n: usize, line_number: u32) usize {
    if (idx == 0) return 0;
    if (idx == n) return @intCast(line_number);

    return @intCast(idx * line_number / n);
}

pub fn makeWorld(world: *std.ArrayList(Object)) void {
    world.appendAssumeCapacity(sphere_ground);

    var a: isize = -11;
    while (a < 11) : (a += 1) {
        var b: isize = -11;
        while (b < 11) : (b += 1) {
            const choose_mat = rand.rf64();
            const af: f64 = @floatFromInt(a);
            const bf: f64 = @floatFromInt(b);

            const center: Point3 = .init(af + 0.9 * rand.rf64(), 0.2, bf + 0.9 * rand.rf64());

            if (center.sub(.init(4, 0.2, 0)).mag() > 0.9) {
                if (choose_mat < 0.8) {
                    const albedo = rand.randomVec3().mulComps(rand.randomVec3());
                    const sphere_material: material.Material = .init(.lambertian, albedo, .{});
                    const sphere: Object = .{ .sphere = .init(center, 0.2, sphere_material) };
                    world.appendAssumeCapacity(sphere);
                } else if (choose_mat < 0.95) {
                    const albedo = rand.randomVec3Bounded(0.5, 1);
                    const fuzz = rand.rf64Bounded(0, 0.5);
                    const sphere_material: material.Material = .init(.metal, albedo, .{ .metal_fuzz = fuzz });
                    const sphere: Object = .{ .sphere = .init(center, 0.2, sphere_material) };
                    world.appendAssumeCapacity(sphere);
                } else {
                    const sphere_material: material.Material = .init(.dielectric, .ones(), .{ .refraction_index = 1.5 });
                    const sphere: Object = .{ .sphere = .init(center, 0.2, sphere_material) };
                    world.appendAssumeCapacity(sphere);
                }
            }
        }
    }
    const material1: material.Material = .init(.dielectric, .ones(), .{ .refraction_index = 1.5 });
    const sphere1: Object = .{ .sphere = .init(.init(0, 1, 0), 1.0, material1) };
    world.appendAssumeCapacity(sphere1);

    const material2: material.Material = .init(.lambertian, .init(0.4, 0.2, 0.1), .{});
    const sphere2: Object = .{ .sphere = .init(.init(-4, 1, 0), 1.0, material2) };
    world.appendAssumeCapacity(sphere2);

    const material3: material.Material = .init(.metal, .init(0.7, 0.6, 0.5), .{ .metal_fuzz = 0.0 });
    const sphere3: Object = .{ .sphere = .init(.init(4, 1, 0), 1.0, material3) };
    world.appendAssumeCapacity(sphere3);
}

pub fn main() !void {
    var arena: std.heap.ArenaAllocator = .init(std.heap.page_allocator);
    const allocator: std.mem.Allocator = arena.allocator();
    defer arena.deinit();

    var threaded: Io.Threaded = .init(allocator, .{});
    const io: Io = threaded.io();

    var file_writer_buffer: [4096]u8 = undefined;
    const file = try Io.Dir.cwd().createFile(io, "data/image.ppm", .{});
    defer file.close(io);
    var file_writer: Io.File.Writer = file.writer(io, &file_writer_buffer);
    var fwriter: *Io.Writer = &file_writer.interface;

    var progess_buffer: [1024]u8 = undefined;
    const stdout: Io.File = .stdout();
    var stdout_writer: Io.File.Writer = stdout.writer(io, &progess_buffer);
    var owriter: *Io.Writer = &stdout_writer.interface;

    const progress = std.Progress.start(io, .{
        .draw_buffer = &progess_buffer,
        .estimated_total_items = camera.image_height,
        .root_name = "Scanlines",
    });

    var world: std.ArrayList(Object) = try .initCapacity(allocator, (22 * 22) + 4);
    makeWorld(&world);

    var list: [thread_number]std.ArrayList(Color) = undefined;

    var threads: [thread_number]std.Thread = undefined;

    for (0..thread_number) |i| {
        const start = getLineNumber(i, thread_number, camera.image_height);
        const end = getLineNumber(i + 1, thread_number, camera.image_height);
        list[i] = try .initCapacity(allocator, (end - start) * camera.image_width);
        threads[i] = try std.Thread.spawn(.{}, renderThread, .{ camera, world.items, start, end, &list[i], progress });
    }

    for (threads) |t| t.join();

    try fwriter.print("P3\n{d} {d}\n255\n", .{ camera.image_width, camera.image_height });

    for (list) |l| {
        for (l.items) |c| {
            try color.writeColor(fwriter, c);
        }
    }

    //try camera.render(fwriter, progress, @constCast(&world));

    try fwriter.flush();
    try owriter.writeAll("\rDone.                      \n");
    try owriter.flush();
}

pub fn renderThread(cam: Camera, w: []Object, start: usize, end: usize, list: *std.ArrayList(Color), progress: ?std.Progress.Node) !void {
    for (start..end) |j| {
        for (0..cam.image_width) |i| {
            list.appendAssumeCapacity(cam.renderPixel(w, i, j));
        }
        if (progress) |prog| {
            prog.completeOne();
        }
    }
}
