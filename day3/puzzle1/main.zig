const std = @import("std");
const print = std.debug.print;

fn biggest_digit(s: []u8) ?usize {
    var best: ?struct { nbr: u8, index: usize } = null;

    for (s, 0..) |digit, i| {
        // I know we're comparing the ascii values of the number but it's in order anyway so who cares lol
        best = if (best) |b| if (b.nbr < digit)
            .{ .nbr = digit, .index = i } // I think I'm falling in love with Zig's syntax
        else
            best else .{ .nbr = digit, .index = i };
    }

    return best.?.index;
}

pub fn main() !void {
    const file = try std.fs.cwd().openFile("input", .{ .mode = .read_only });
    defer file.close();

    var reader = file.reader();

    var buf: [1024]u8 = undefined;
    var line_nbr: u32 = 0;

    var acc: u64 = 0;
    while (try reader.readUntilDelimiterOrEof(&buf, '\n')) |line| : (line_nbr += 1) {
        const first = biggest_digit(line[0 .. line.len - 1]) orelse unreachable;
        const seccond = first + 1 + (biggest_digit(line[first + 1 ..]) orelse unreachable);

        const best = std.fmt.parseInt(u10, &.{ line[first], line[seccond] }, 10) catch unreachable;

        print("Best 2digits for {s} is {d} ({d}, {d})\n", .{ line, best, first, seccond });

        acc += best;
    }

    print("Total accumulator: {d}\n", .{acc});
}
