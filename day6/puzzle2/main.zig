const std = @import("std");
const print = std.debug.print;

const Operation = enum { Mul, Add };

pub fn main() !void {
    const file = try std.fs.cwd().openFile("input", .{});
    defer file.close();

    const reader = file.reader();
    var buffer: [4096]u8 = undefined;
    var line_count: u32 = 0;

    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    defer _ = gpa.deinit();

    var lines = std.ArrayList(std.ArrayList(u8)).init(gpa.allocator());
    defer {
        while (lines.items.len != 0) {
            const line: std.ArrayList(u8) = lines.swapRemove(0);
            line.deinit();
        }
        lines.deinit();
    }

    var nbr_str = try std.ArrayList(u8).initCapacity(gpa.allocator(), 10);
    defer nbr_str.deinit();

    var operator_positions = try std.ArrayList(usize).initCapacity(gpa.allocator(), 100);
    defer operator_positions.deinit();

    while (try reader.readUntilDelimiterOrEof(&buffer, '\n')) |line| : (line_count += 1) {
        var lst = try std.ArrayList(u8).initCapacity(gpa.allocator(), line.len);

        try lst.appendSlice(line);

        try lines.append(lst);
    }

    const t1 = std.time.microTimestamp();

    for (lines.getLast().items, 0..) |s_operator, i| {
        if (s_operator == ' ') continue;

        try operator_positions.append(i);
    }

    // print("Got {d} operators\n", .{operator_positions.items.len});

    var global_acc: usize = 0;
    for (0..operator_positions.items.len) |i| {
        const curr_pos = operator_positions.items[i];

        const next_pos = if (i + 1 < operator_positions.items.len)
            operator_positions.items[
                i + 1
            ] - 1
        else
            lines.getLast().items.len;
        const operator = lines.getLast().items[curr_pos];

        // print("Operator: {c}({d}) ({d}-{d}): ", .{ operator, i, curr_pos, next_pos });

        var acc: u64 = switch (operator) {
            '*' => 1,
            '+' => 0,
            else => unreachable,
        };

        for (curr_pos..next_pos) |j| {
            var k: usize = 0;

            while (k < lines.items.len - 1) : (k += 1) {
                const row: std.ArrayList(u8) = lines.items[k];
                const char = row.items[j];
                if (char == ' ') continue;
                try nbr_str.append(char);
            }

            // print("nbr_str: '{s}'\n", .{nbr_str.items});
            const nbr = try std.fmt.parseInt(u64, nbr_str.items, 10);

            switch (operator) {
                '*' => acc *= nbr,
                '+' => acc += nbr,
                else => unreachable,
            }
            nbr_str.clearRetainingCapacity();
        }

        global_acc += acc;

        // var j: usize = 0;
        // while (j < lines.items.len - 1) : (j += 1) {
        //     const row: std.ArrayList(u8) = lines.items[j];

        //     const nbr_str: []u8 = row.items[curr_pos..next_pos];

        //     print("'{s}' ", .{nbr_str});
        // }
        // print("\n", .{});
    }

    // for (lines.items) |line| {
    //     print("{s}\n", .{line.items});
    // }
    const t2 = std.time.microTimestamp();

    print("Global acc: {d}, in {d}ms\n", .{ global_acc, @as(f64, @floatFromInt(t2 - t1)) * 0.001 });
}
