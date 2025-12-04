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

fn remove_rolls(world: std.ArrayList(u8), world_width: usize, movables: std.ArrayList(Pos)) void {
    for (movables) |pos| {
        world[index2d(pos.x, pos.y, world_width)];
    }
}

fn find_removable(world: std.ArrayList(u8), world_width: usize, world_height: usize, allocator: std.mem.Allocator) !std.ArrayList(Pos) {
    var movable_array = std.ArrayList(Pos).init(allocator);

    for (0..world_height) |y| for (0..world_width) |x| {
        // print("{d} - {d} - {c}\n", .{ x, y, world.items[index2d(x, y, world_width)] });

        if (world.items[index2d(x, y, world_width)] != '@') continue;

        var roll_count: u16 = 0;
        for (0..3) |uny| for (0..3) |unx| {
            if (unx == 1 and uny == 1) continue;

            const nx = (@as(isize, @intCast(unx)) - 1) + @as(isize, @intCast(x));
            const ny = (@as(isize, @intCast(uny)) - 1) + @as(isize, @intCast(y));

            if (nx < 0 or ny < 0 or nx >= world_width or ny >= world_height) continue;

            if (world.items[index2d(@intCast(nx), @intCast(ny), world_width)] == '@') {
                roll_count += 1;
            }
        };

        if (roll_count < 4) {
            try movable_array.append(.{ .x = x, .y = y });
        }
    };
    return movable_array;
}

pub fn main() !void {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    defer _ = gpa.deinit();

    const file = try std.fs.cwd().openFile("./input", .{ .mode = .read_only });
    defer file.close();

    var reader = file.reader();

    var buf: [4096]u8 = undefined;

    var world = std.ArrayList(u8).init(gpa.allocator());
    defer world.deinit();

    var width: ?usize = null;
    var height: usize = 0;
    while (try reader.readUntilDelimiterOrEof(&buf, '\n')) |line| : (height += 1) {
        if (width == null) {
            width = line.len;
        } else {
            std.debug.assert(line.len == width.?);
        }
        try world.appendSlice(line);
    }

    var total_removed: usize = 0;
    while (true) {
        const allocator = gpa.allocator();

        const movable_array = try find_removable(world, width.?, height, allocator);
        defer movable_array.deinit();

        if (movable_array.items.len == 0) {
            break;
        }

        total_removed += movable_array.items.len;

        // const stdout = std.io.getStdOut().writer();
        // var buffer = std.io.bufferedWriter(stdout);
        // for (0..height) |y| {
        //     var writer = buffer.writer();
        //     for (0..width.?) |x| {
        //         if (x == 0) {
        //             print("\n", .{});
        //         }

        //         var char = world.items[index2d(x, y, width.?)];
        //         if (inSlice(Pos, movable_array.items, .{ .x = x, .y = y })) {
        //             try writer.print("\x1B[32m{c}\x1B[0m", .{char});
        //         } else {
        //             if (char == '.'){
        //                 char = ' ';
        //             }
        //             try writer.print("{c}", .{char});
        //         }
        //     }
        //     try buffer.flush();
        // }
        // print("\n", .{});

        for (movable_array.items) |pos| {
            world.items[index2d(pos.x, pos.y, width.?)] = '.';
        }

        // print("There is {d} movable rolls\n", .{movable_array.items.len});
    }

    print("Removed {d} rolls in total", .{total_removed});
}
