const std = @import("std");
const mem = std.mem;
const Allocator = mem.Allocator;
const assert = std.debug.assert;
const print = std.debug.print;
const input = @embedFile("../in/day03.txt");

const Slope = struct {
    right: usize,
    down:  usize
};

fn treeCount(it: *mem.SplitIterator, slope: Slope) usize {
    var trees: usize = 0;
    var col: usize = slope.right; 
    while (true) : (col += slope.right) {
        // skip the remaining lines preceding the next checkpoint
        var y: usize = 1; 
        while (y < slope.down) : (y += 1) {
            _ = it.next();
        }

        if (it.next()) |row| {
            switch (row[col % row.len]) {
                '#' => trees += 1,
                else => continue
            }
        } else {
            return trees;
        }
    }
}

pub fn main() !void {
    var it = mem.split(input, "\n");
    _ = it.next(); // skip the first line bc it doesn't have a checkpoint.
    
    // ----------- Part 1 -----------
    var it1 = it;
    const p1 = treeCount(&it1, Slope{.right = 3, .down = 1});
    print("part1: {}\n", .{p1});

    // ----------- Part 2 -----------
    const slopes = [_]Slope{
        Slope{.right = 1, .down = 1},
        Slope{.right = 3, .down = 1},
        Slope{.right = 5, .down = 1},
        Slope{.right = 7, .down = 1},
        Slope{.right = 1, .down = 2},
    };

    var product: usize = 1;
    for (slopes) |slope| {
        var itn = it;
        product *= treeCount(&itn, slope);
    }
    print("part2: {}\n", .{product});
}

test "tree count" {
    var it = mem.split(input, "\n");
    const cnt = treeCount(&it, );
    print("\n{}\n", .{cnt});
}