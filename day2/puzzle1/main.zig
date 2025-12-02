const std = @import("std");
const print = std.debug.print;

const Range = struct {
    low: u64,
    high: u64,
};

fn read_ranges() !std.ArrayList(Range) {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    // defer _ = gpa.deinit();

    const file = try std.fs.cwd().openFile("input", .{ .mode = .read_only });
    defer file.close();

    var reader = std.io.bufferedReader(file.reader());
    var stream = reader.reader();

    var buf: [1024]u8 = undefined;
    var line_nbr: u32 = 0;

    var ranges = std.ArrayList(Range).init(gpa.allocator());
    errdefer ranges.deinit();

    // For some reason (idk if it's zig or the way I downloaded the input but), a new line character is always at the end of the file
    // I could set the delimiter to "\n", then loop again for every range, but I don't like it.
    while (try stream.readUntilDelimiterOrEof(&buf, ',')) |line| : (line_nbr += 1) {
        // So I'm gonna filter this lf
        const srange = if (line[line.len - 1] == '\n')
            line[0..(line.len - 1)]
        else
            line;

        print("\nSRange: {s} - {any}\n", .{ srange, srange });
        var split = std.mem.splitScalar(u8, srange, '-');

        const slow = split.next() orelse {
            print("Could not extract the lower value of the range", .{});
            continue;
        };
        const shigh = split.next() orelse {
            print("Could not extract the upper value of the range", .{});
            continue;
        };

        const range = Range{
            .low = try std.fmt.parseInt(u64, slow, 10),
            .high = try std.fmt.parseInt(u64, shigh, 10),
        };

        print("Range: {}\n", .{range});

        ranges.append(range) catch |e| {
            print("Failed to append {} to the range arraylist due to: {}", .{ range, e });
        };
    }

    return ranges;
}

fn check_range(range: Range) ![]u64 {
    print("{}\n", .{range});
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};

    var invalid_ids = std.ArrayList(u64).init(gpa.allocator());

    for (range.low..range.high + 1) |id| {
        if (try validate_id(id)) {
            continue;
        }

        print("{d}\n", .{id});

        try invalid_ids.append(id);
    }
    print("\n", .{});
    return invalid_ids.items;
}

fn validate_id(id: u64) !bool {
    var valid = true;

    var buf: [20]u8 = .{0} ** 20;

    const digits = try std.fmt.bufPrint(&buf, "{}", .{id});

    // Ascii sht, since I'm technically printing as a string, it has a offset of 48 to fit the ascci table.
    for (0..digits.len) |i| {
        buf[i] = buf[i] - 48;
    }

    // If nbr of digit is odd, it cannot repeat a sequence twice without skipping any digits
    if (@mod(digits.len, 2) != 0) {
        return true;
    }
   
    if (slice_equal(digits[0 .. digits.len / 2], digits[digits.len / 2 ..])) {
        valid = false;
    }

    return valid;
}

fn slice_equal(first: []u8, seccond: []u8) bool {
    // Should have already been checked
    if (first.len != seccond.len) {
        unreachable;
        // return false;
    }

    for (0..first.len) |i| {
        if (first[i] != seccond[i]) {
            return false;
        }
    }
    return true;
}

pub fn main() !void {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    defer _ = gpa.deinit();

    const ranges = try read_ranges();
    defer ranges.deinit();

    var invalid_ids = std.ArrayList(u64).init(gpa.allocator());
    defer invalid_ids.deinit();

    for (ranges.items) |range| {
        const range_invalid_ids = try check_range(range);

        if (range_invalid_ids.len == 0) {
            continue;
        }

        try invalid_ids.appendSlice(range_invalid_ids);
    }

    var total = @as(u64, 0);

    for (invalid_ids.items) |invalid_id| {
        total += invalid_id;
        print("Invalid: {d} - {d}\n", .{ invalid_id, total });
    }
}
