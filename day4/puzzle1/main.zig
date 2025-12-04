const std = @import("std");
const print = std.debug.print;

fn index2d(x: usize, y: usize, width: usize) usize {
    return y * width + x;
}

pub fn inSlice(comptime T: type, haystack: []const T, needle: T) bool {
    for (haystack) |thing| {
        if (std.meta.eql(thing, needle)) {
            return true;
        }
    }
    return false;
}

const Pos = struct {
    x: usize,
    y: usize,
};

pub fn main() !void {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    defer _ = gpa.deinit();

    const file = try std.fs.cwd().openFile("input", .{ .mode = .read_only });
    defer file.close();

    var reader = file.reader();

    var buf: [4096]u8 = undefined;

    var world = std.ArrayList(u8).init(gpa.allocator());
    defer world.deinit();

    var width: ?usize = null;
    var height: u32 = 0;
    while (try reader.readUntilDelimiterOrEof(&buf, '\n')) |line| : (height += 1) {
        if (width == null) {
            width = line.len;
        } else {
            std.debug.assert(line.len == width.?);
        }
        try world.appendSlice(line);
    }

    var movable_array = std.ArrayList(Pos).init(gpa.allocator());
    defer movable_array.deinit();

    var movable_count: u16 = 0;
    for (0..height) |y| for (0..width.?) |x| {
        print("{d} - {d} - {c}\n", .{ x, y, world.items[index2d(x, y, width.?)] });

        if (world.items[index2d(x, y, width.?)] != '@') continue;

        var roll_count: u16 = 0;
        for (0..3) |uny| for (0..3) |unx| {
            if (unx == 1 and uny == 1) continue;

            const nx = (@as(isize, @intCast(unx)) - 1) + @as(isize, @intCast(x));
            const ny = (@as(isize, @intCast(uny)) - 1) + @as(isize, @intCast(y));

            if (nx < 0 or ny < 0 or nx >= width.? or ny >= height) continue;

            if (world.items[index2d(@intCast(nx), @intCast(ny), width.?)] == '@') {
                roll_count += 1;
            }
        };

        if (roll_count < 4) {
            try movable_array.append(.{ .x = x, .y = y });
            movable_count += 1;
        }
    };

    for (0..height) |y| for (0..width.?) |x| {
        if (x == 0) {
            print("\n", .{});
        }

        const char = world.items[index2d(x, y, width.?)];
        if (inSlice(Pos, movable_array.items, .{ .x = x, .y = y })) {
            print("\x1B[32m{c}\x1B[0m", .{char});
        } else {
            print("{c}", .{char});
        }
    };

    print("\n\n", .{});

    print("There is {d} movable rolls", .{movable_count});
}
