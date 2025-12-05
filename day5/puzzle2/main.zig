const std = @import("std");
const print = std.debug.print;

const ParseMode = enum { Ranges, Ids };

const Range = struct {
    low: usize,
    high: usize,
};

fn quicksort_partition(a: *std.ArrayList(Range), lo: usize, hi: usize) usize {
    const pivot = a.items[hi];
    var i = lo;

    for (lo..hi) |j| {
        if (a.items[j].low > pivot.low) continue;
        std.mem.swap(Range, &a.items[i], &a.items[j]);
        i += 1;
    }
    std.mem.swap(Range, &a.items[i], &a.items[hi]);
    return i;
}

fn quicksort(a: *std.ArrayList(Range), lo: usize, hi: usize) void {
    if (lo >= hi) return;

    const p = quicksort_partition(a, lo, hi);

    if (p > 0) {
        quicksort(a, lo, p - 1);
    }
    quicksort(a, p + 1, hi);
}

fn merge(ranges: std.ArrayList(Range), new: *std.ArrayList(Range)) !void {
    var j: usize = 0;

    while (j < ranges.items.len) {
        var nrange = ranges.items[j];
        j += 1;

        var is_needed = true;

        var i: usize = 0;

        while (i < new.items.len) {
            const range = new.items[i];
            if (nrange.low <= range.low and range.low <= nrange.high) {
                // print("Updating {any}'s low\n", .{range});
                new.items[i].low = nrange.low;
                is_needed = false;
            }

            if (nrange.high >= range.high and range.high >= nrange.low) {
                // print("Updating {any}'s high\n", .{range});
                new.items[i].high = nrange.high;
                is_needed = false;
            }

            if (!is_needed) {
                break;
            }

            var saved_needed = true;
            if (range.low < nrange.low and nrange.low < range.high) {
                // print("Updating (2) {any}'s low\n", .{nrange});
                nrange.low = range.low;
                saved_needed = false;
            }

            if (range.high > nrange.high and nrange.high > range.low) {
                // print("Updating (2) {any}'s high\n", .{nrange});
                nrange.high = range.high;
                saved_needed = false;
            }

            if (!saved_needed) {
                _ = new.swapRemove(i);
            } else {
                i += 1;
            }
        }

        if (!is_needed) {
            // print("Skip\n", .{});
            continue;
        }

        try new.append(nrange);
    }
}

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

    var current_mode: ParseMode = ParseMode.Ranges;

    while (try reader.readUntilDelimiterOrEof(&buf, '\n')) |line| : (line_count += 1) {
        if (line.len == 0 and current_mode == ParseMode.Ranges) {
            print("End of ranges, got {d}\n", .{ranges.items.len});
            current_mode = ParseMode.Ids;
            break;
        }
        switch (current_mode) {
            ParseMode.Ranges => {
                var iter = std.mem.splitAny(u8, line, "-");
                try ranges.append(Range{
                    .low = try std.fmt.parseInt(usize, iter.next() orelse unreachable, 10),
                    .high = try std.fmt.parseInt(usize, iter.next() orelse unreachable, 10),
                });
            },
            ParseMode.Ids => {
                unreachable;
            },
        }
    }

    var new = try std.ArrayList(Range).initCapacity(gpa.allocator(), 100);
    defer new.deinit();

    const t1 = std.time.microTimestamp();

    quicksort(&ranges, 0, ranges.items.len - 1);
    try merge(ranges, &new);


    var total: usize = 0;

    for (new.items) |range| {
        total += range.high + 1 - range.low;
    }
    const t2 = std.time.microTimestamp();

    print("Got {d} ranges after merge\n", .{new.items.len});
    print("There is {d} allowed ids, in {d}ms\n", .{ total, @as(f64, @floatFromInt(t2 - t1)) * 0.001 });
}
