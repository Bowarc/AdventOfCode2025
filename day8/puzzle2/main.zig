const std = @import("std");
const print = std.debug.print;
const Tuple = std.meta.Tuple;

const Pos3d = struct {
    x: i64,
    y: i64,
    z: i64,

    fn dist_to(self: @This(), other: @This()) !u32 {
        // const x =
        //     @as(u64, @intCast(try std.math.powi(i64, @intCast(other.x) - @intCast(self.x)), 2)));
        // const y =
        //     @as(u64, @intCast(try std.math.powi(i64, @intCast(other.y) - @intCast(self.y)), 2)));
        // const z =
        //     @as(u64, @intCast(try std.math.powi(i64, @intCast(other.z) - @intCast(self.z)), 2)));

        const x = try std.math.powi(i64, other.x - self.x, 2);
        const y = try std.math.powi(i64, other.y - self.y, 2);
        const z = try std.math.powi(i64, other.z - self.z, 2);

        return std.math.sqrt(@as(u64, @intCast(x)) +
            @as(u64, @intCast(y)) +
            @as(u64, @intCast(z)));
    }
    pub fn format(
        self: @This(),
        comptime fmt: []const u8,
        options: std.fmt.FormatOptions,
        writer: anytype,
    ) !void {
        _ = fmt;
        _ = options;

        try writer.print("@Pos3d{{x: {d}, y: {d}, z: {d}}}", .{ self.x, self.y, self.z });
    }
};

const Pair = struct {
    i1: usize,
    i2: usize,
    dist: u32,

    fn max() Pair {
        return .{ .i1 = 0, .i2 = 0, .dist = 4_294_967_295 };
    }
    pub fn format(
        self: @This(),
        comptime fmt: []const u8,
        options: std.fmt.FormatOptions,
        writer: anytype,
    ) !void {
        _ = fmt;
        _ = options;

        try writer.print("@Pair{{i1: {d}, i2: {d}, dist: {d}}}", .{ self.i1, self.i2, self.dist });
    }
};

const UnionFind = struct {
    parent: std.ArrayList(usize),

    fn init(size: usize, allocator: std.mem.Allocator) !@This() {
        var parent = try std.ArrayList(usize).initCapacity(allocator, size);

        for (0..size) |i| {
            try parent.append(i);
        }
        return .{ .parent = parent };
    }
    fn deinit(self: @This()) void {
        self.parent.deinit();
    }

    fn find(self: @This(), i: usize) usize {
        if (self.parent.items[i] == i) return i;

        return self.find(self.parent.items[i]);
    }

    fn unite(self: @This(), i: usize, j: usize) void {
        const irep = self.find(i);
        const jrep = self.find(j);

        self.parent.items[irep] = jrep;
    }
};

fn lessThan(context: void, a: Pair, b: Pair) bool {
    _ = context;
    return a.dist < b.dist;
}

fn map_by_distance(boxes: std.ArrayList(Pos3d), allocator: std.mem.Allocator) !std.ArrayList(Pair) {
    var map = std.ArrayList(Pair).init(allocator);

    for (0..boxes.items.len) |i| for (i + 1..boxes.items.len) |j| {
        try map.append(Pair{ .i1 = i, .i2 = j, .dist = try boxes.items[i].dist_to(boxes.items[j]) });
    };

    std.sort.block(Pair, map.items, {}, lessThan);

    var used = std.ArrayList(usize).init(allocator);
    defer used.deinit();

    return map;
}

pub fn main() !void {
    const file = try std.fs.cwd().openFile("input", .{});
    defer file.close();

    var reader = file.reader();
    var file_buffer: [1024]u8 = undefined;

    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    defer _ = gpa.deinit();

    var boxes = std.ArrayList(Pos3d).init(gpa.allocator());
    defer boxes.deinit();

    var line_count: u32 = 0;

    while (try reader.readUntilDelimiterOrEof(&file_buffer, '\n')) |line| : (line_count += 1) {
        var iterator = std.mem.splitScalar(u8, line, ',');

        try boxes.append(Pos3d{
            .x = try std.fmt.parseInt(i64, iterator.next().?, 10),
            .y = try std.fmt.parseInt(i64, iterator.next().?, 10),
            .z = try std.fmt.parseInt(i64, iterator.next().?, 10),
        });
    }

    const closest_map = try map_by_distance(boxes, gpa.allocator());

    var uf = try UnionFind.init(line_count, gpa.allocator());

    var c: usize = 0;
    while (true) : (c += 1) {
        const closest = closest_map.items[c];
        // for (closest_map.items) |closest| {
        // if (uf.find(closest.i1) != closest.i1 or uf.find(closest.i2) != closest.i2) continue;
        // print("Pair: {s}-{s} ({d})\n", .{ boxes.items[closest.i1], boxes.items[closest.i2], closest.dist });
        uf.unite(closest.i1, closest.i2);

        var done = true;
        const base_grp_nbr = uf.find(0);
        for (0..line_count) |lc| {
            if (uf.find(lc) == base_grp_nbr) continue;
            done = false;
        }
        if (done) {
            print("Last 2 box's X multiplied: {d}", .{boxes.items[closest.i1].x * boxes.items[closest.i2].x});
            break;
        }
        continue;
    }

    uf.deinit();

    // }
    closest_map.deinit();

    // print("There is {d} junction boxed\n", .{boxes.items.len});
}
