const std = @import("std");
const print = std.debug.print;

pub fn main() !void {
    const file = try std.fs.cwd().openFile("input", .{});
    defer file.close();

    var reader = file.reader();
    var file_buffer: [2048]u8 = undefined;

    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    defer _ = gpa.deinit();

    var splitters_x = std.ArrayList(std.ArrayList(usize)).init(gpa.allocator());
    defer {
        while (splitters_x.pop()) |row| {
            row.deinit();
        }
        splitters_x.deinit();
    }

    var inital_beam_x: usize = 0;

    var line_i: usize = 0;
    var line_width: u16 = 0;
    while (try reader.readUntilDelimiterOrEof(&file_buffer, '\n')) |line| : (line_i += 1) {
        if (line_width == 0) {
            line_width = @intCast(line.len);
        } else {
            std.debug.assert(line_width == line.len);
        }
        if (line_i == 0) {
            inital_beam_x = std.mem.indexOf(u8, line, "S") orelse {
                @panic("Failed to find tachyon beam");
            };
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

    var tachyons_timelines_map = try std.ArrayList(usize).initCapacity(gpa.allocator(), line_width);
    defer tachyons_timelines_map.deinit();
    try tachyons_timelines_map.appendNTimes(0, line_width);
    tachyons_timelines_map.items[inital_beam_x] = 1;

    var tachyons_timelines_map_buff2 = try std.ArrayList(usize).initCapacity(gpa.allocator(), line_width);
    defer tachyons_timelines_map_buff2.deinit();
    try tachyons_timelines_map_buff2.appendNTimes(0, tachyons_timelines_map.items.len);

    const t1 = std.time.microTimestamp();

    var timelines: u64 = 1;
    for (splitters_x.items) |row| {
        // print("Row: {d}\n", .{d});
        // print("Checking {any} against {any} -> {any}\n", .{ tachyons_timelines_map.items, row.items, tachyons_timelines_map_buff2.items });

        for (row.items) |splitter_x| {
            const count = tachyons_timelines_map.items[splitter_x];
            tachyons_timelines_map.items[splitter_x] = 0;
            tachyons_timelines_map_buff2.items[splitter_x - 1] += count;
            tachyons_timelines_map_buff2.items[splitter_x + 1] += count;
            timelines += count;
        }

        for (tachyons_timelines_map.items, 0..) |remaining, x| {
            tachyons_timelines_map_buff2.items[x] += remaining;
        }

        std.mem.swap(std.ArrayList(usize), &tachyons_timelines_map, &tachyons_timelines_map_buff2);
        @memset(tachyons_timelines_map_buff2.items[0..], 0);
    }
    const t2 = std.time.microTimestamp();

    print("There was {d} splits in {d} rows, in {d}ms\n", .{ timelines, splitters_x.items.len,  @as(f64, @floatFromInt(t2 - t1)) * 0.001 });
}
