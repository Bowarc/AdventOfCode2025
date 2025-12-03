const std = @import("std");
const print = std.debug.print;

fn biggest_digit(s: []u8) usize {
    // std.testing.expect(s.len != 0) catch std.debug.panic("Hi :3", .{});

    var best: struct { nbr: u64, index: usize } = .{ .nbr = s[0], .index = 0 };

    for (s[1..], 1..) |digit, i| {
        // I know we're comparing the ascii values of the number but it's in order anyway so who cares lol
        if (best.nbr < digit) {
            best = .{ .nbr = digit, .index = i };
        }
    }

    return best.index;
}

inline fn display_bool_array(in: []bool) [100]u8 {
    var out: [100]u8 = .{0} ** 100;

    for (in, 0..) |b, i| {
        out[i] = if (b) 1 else 0;
    }
    return out;
}

pub fn main() !void {
    const file = try std.fs.cwd().openFile("input", .{ .mode = .read_only });
    defer file.close();

    var reader = file.reader();

    var buf: [1024]u8 = undefined;
    var line_nbr: u32 = 0;

    var acc: u64 = 0;
    while (try reader.readUntilDelimiterOrEof(&buf, '\n')) |line| : (line_nbr += 1) {
        var best_nbr: [12]u8 = .{0} ** 12;

        var left: usize = 0;
        print("Line: {s}\n", .{line});
        for (0..best_nbr.len) |i| {
            const right = line.len - (best_nbr.len - 1 - i);
            const slice = line[left..right];
            const best_index = biggest_digit(slice);
            print("({c}-{d}) {d}-{d} - {s}\x1B[32m{c}\x1B[0m{s}\n", .{ slice[best_index], best_index, left, right, slice[0..best_index], slice[best_index], slice[best_index + 1 ..] });
            best_nbr[i] = slice[best_index];
            left += best_index + 1;
        }

        acc += try std.fmt.parseInt(u64, &best_nbr, 10);

        print("{s}\n\n", .{best_nbr});
    }

    print("Total accumulator: {d}\n", .{acc});
}
