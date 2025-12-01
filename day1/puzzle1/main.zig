const std = @import("std");

pub fn main() !void {
    const file = try std.fs.cwd().openFile("input", .{ .mode = .read_only });
    defer file.close();

    var reader = std.io.bufferedReader(file.reader());
    var stream = reader.reader();

    var buf: [1024]u8 = undefined;
    var line_nbr: u32 = 0;

    var dial_position: i32 = 50;
    var times_it_hit_zero: u16 = 0;
    while (try stream.readUntilDelimiterOrEof(&buf, '\n')) |line| : (line_nbr += 1) {
        const amt = try std.fmt.parseInt(i16, line[1..], 10) * if (line[0] == 'R') @as(i16, 1) else @as(i16, -1);

        dial_position = @mod(dial_position + amt, 100);

        if (dial_position == 0) {
            times_it_hit_zero += 1;
        }

        std.debug.print("Line {d}: {d:3} --- {d} \n", .{ line_nbr, amt, dial_position });
    }

    std.debug.print("The code is: {d}, dial position is {d}", .{ times_it_hit_zero, dial_position });
}
