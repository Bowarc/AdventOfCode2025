const std = @import("std");
const print = std.debug.print;

pub fn main() !void {
    const file = try std.fs.cwd().openFile("input", .{});
    defer file.close();

    var reader = file.reader();
    var file_buffer: [2048]u8 = undefined;

    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    defer _ = gpa.deinit();

    var tachyon_beams_x = std.ArrayList(usize).init(gpa.allocator());
    defer tachyon_beams_x.deinit();

    var splitters_x = std.ArrayList(std.ArrayList(usize)).init(gpa.allocator());
    defer {
        while (splitters_x.pop()) |row| {
            row.deinit();
        }
        splitters_x.deinit();
    }

    var line_i: usize = 0;
    while (try reader.readUntilDelimiterOrEof(&file_buffer, '\n')) |line| : (line_i += 1) {
        if (line_i == 0) {
            try tachyon_beams_x.append(std.mem.indexOf(u8, line, "S") orelse {
                @panic("Failed to find tachyon beam");
            });
            continue;
        }
        var current_splitters_x = std.ArrayList(usize).init(gpa.allocator());

        for (line, 0..) |elem, i| {
            if (elem == '.') continue;
            try current_splitters_x.append(i);
        }

        if (current_splitters_x.items.len == 0) {
            current_splitters_x.deinit();
            continue;
        }

        try splitters_x.append(current_splitters_x);
    }

    for (splitters_x.items, 0..) |sx, i| {
        print("Row {d} splitters: {any}\n", .{ i, sx.items });
    }

    var total_splits: u16 = 0;
    for (splitters_x.items, 0..) |row, d| {
        var new_tachyons_beam_x = std.ArrayList(usize).init(gpa.allocator());

        print("Checking {any} against {any}\n", .{ tachyon_beams_x.items, row.items });
        for (tachyon_beams_x.items) |beam_x| {
            var has_hit = false;

            for (row.items) |spliter_x| {
                if (beam_x != spliter_x) continue;

                var new_split = false;
                for ([_]i32{ -1, 1 }) |dir| {
                    const pos = beam_x + @as(usize, @intCast(dir + 1)) - 1;
                    if (std.mem.indexOfScalar(usize, new_tachyons_beam_x.items, pos) != null) continue;
                    print("row {d} split #{d} at {d} -> {d}\n", .{ d, new_tachyons_beam_x.items.len, spliter_x, pos });

                    try new_tachyons_beam_x.append(pos);
                    new_split = true;
                }

                if (new_split) total_splits += 1;
                has_hit = true;
            }
            if (!has_hit) {
                try new_tachyons_beam_x.append(beam_x);
            }
        }
        tachyon_beams_x.clearRetainingCapacity();
        tachyon_beams_x.deinit();
        tachyon_beams_x = new_tachyons_beam_x;
    }

    print("There was {d} splits in {d} rows", .{ total_splits, splitters_x.items.len });
}
