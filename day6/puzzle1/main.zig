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

    var scalar_lines = std.ArrayList(std.ArrayList(usize)).init(gpa.allocator());
    defer {
        while (scalar_lines.items.len != 0) {
            const line: std.ArrayList(usize) = scalar_lines.swapRemove(0);
            line.deinit();
        }
        scalar_lines.deinit();
    }

    var global_acc: usize = 0;
    while (try reader.readUntilDelimiterOrEof(&buffer, '\n')) |line| : (line_count += 1) {
        var line_elems = std.mem.splitScalar(u8, line, ' ');

        // For some reason there is a ton of random spaces in the input file
        while (true) {
            const elem = line_elems.peek() orelse unreachable;
            if (elem.len == 0) {
                _ = line_elems.next();
            } else {
                break;
            }
        }

        const first_elem_first_char = (line_elems.peek() orelse unreachable)[0];
        print("First char of first elem: {c}\n", .{first_elem_first_char});

        if (first_elem_first_char == '+' or first_elem_first_char == '*') {

            // This means that we reached the operation line

            var i: usize = 0;
            while (line_elems.next()) |elem| {
                if (elem.len == 0) continue; // For some reason there is a ton of random spaces in the input file
                defer i += 1;

                const operator: Operation = switch (elem[0]) {
                    '+' => Operation.Add,
                    '*' => Operation.Mul,
                    else => unreachable,
                };

                var acc: u64 = 0;
                for (scalar_lines.items) |scalar_line| {
                    switch (operator) {
                        .Add => acc += scalar_line.items[i],
                        .Mul => {
                            if (acc == 0) acc = 1;
                            acc = acc * scalar_line.items[i];
                        },
                    }
                }

                print("I: {d}, acc: {d}\n", .{ i, acc });
                global_acc += acc;
            }
        } else {
            var line_scalars = try std.ArrayList(usize).initCapacity(gpa.allocator(), 50);

            while (line_elems.next()) |elem| {
                if (elem.len == 0) continue;
                const nbr = try std.fmt.parseInt(usize, elem, 10);

                try line_scalars.append(nbr);
            }

            try scalar_lines.append(line_scalars);
        }
    }

    print("Global acc: {d}\n", .{global_acc});
}
