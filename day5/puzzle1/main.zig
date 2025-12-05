const std = @import("std");
const print = std.debug.print;

const ParseMode = enum { Ranges, Ids };

const Range = struct {
    low: usize,
    high: usize,
};

pub fn main() !void {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    defer _ = gpa.deinit();

    const file = try std.fs.cwd().openFile("input", .{ .mode = .read_only });
    defer file.close();

    var reader = file.reader();

    var buf: [4096]u8 = undefined;
    var line_count: u32 = 0;

    var ranges = std.ArrayList(Range).init(gpa.allocator());
    defer ranges.deinit();

    var ids = std.ArrayList(usize).init(gpa.allocator());
    defer ids.deinit();

    var current_mode: ParseMode = ParseMode.Ranges;

    while (try reader.readUntilDelimiterOrEof(&buf, '\n')) |line| : (line_count += 1) {
        if (line.len == 0 and current_mode == ParseMode.Ranges) {
            print("End of ranges, got {d}\n", .{ranges.items.len});
            current_mode = ParseMode.Ids;
            continue;
        }
        switch (current_mode) {
            ParseMode.Ranges => {
                var iter = std.mem.splitAny(u8, line, "-");
                var nrange = Range{
                    .low = try std.fmt.parseInt(usize, iter.next() orelse unreachable, 10),
                    .high = try std.fmt.parseInt(usize, iter.next() orelse unreachable, 10),
                };

                // print("Testing: {any}\n", .{nrange});

                var is_needed = true;

                var i: usize = 0;

                // This could be called in a loop to fix issues like
                // Range: 3 - 5
                // Range: 10 - 18
                // Range: 16 - 20

                // being generated
                //
                // Btw this is probably slower than just checking all the ranges
                while (i < ranges.items.len) {
                    const range = ranges.items[i];
                    if (nrange.low < range.low and range.low < nrange.high) {
                        print("Updating {any}'s low\n", .{range});
                        ranges.items[i].low = nrange.low;
                        is_needed = false;
                    }

                    if (nrange.high > range.high and range.high > nrange.low) {
                        print("Updating {any}'s high\n", .{range});
                        ranges.items[i].high = nrange.high;
                        is_needed = false;
                    }

                    if (!is_needed) {
                        break;
                    }

                    var saved_needed = true;
                    if (range.low < nrange.low and nrange.low < range.high) {
                        print("Updating (2) {any}'s low\n", .{nrange});
                        nrange.low = range.low;
                        saved_needed = false;
                    }

                    if (range.high > nrange.high and nrange.high > range.low) {
                        print("Updating (2) {any}'s high\n", .{nrange});
                        nrange.high = range.high;
                        saved_needed = false;
                    }

                    if (!saved_needed) {
                        _ = ranges.orderedRemove(i);
                    } else {
                        i += 1;
                    }
                }

                if (!is_needed) {
                    // print("Skip\n", .{});
                    continue;
                }

                try ranges.append(nrange);
            },
            ParseMode.Ids => {
                try ids.append(try std.fmt.parseInt(usize, line, 10));
            },
        }
    }
    print("End of ids, got {d}\n", .{ids.items.len});

    var fresh_count: u16 = 0;
    for (ids.items) |id| {
        var good = false;
        for (ranges.items) |range| {
            if (range.low >= id or range.high <= id) continue;
            good = true;
        }
        if (!good) continue;

        fresh_count += 1;
    }

    print("There is {d} valid ids\n", .{fresh_count});
}
