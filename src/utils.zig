const std = @import("std");
const mem = std.mem;
const fmt = std.fmt;
const hash_map = std.hash_map;
const math = std.math;
const meta = std.meta;

// *****************************************************************************

pub fn splitToInts(comptime T: type, allocator: *mem.Allocator, 
                   buffer: []const u8, delim: []const u8
) ![]T {
    var ints = std.ArrayList(T).init(allocator);
    errdefer ints.deinit();

    var it = mem.split(buffer, delim);
    while (it.next()) |field| {
        if (field.len == 0) continue;
        const int = try fmt.parseInt(T, field, 10);
        try ints.append(int);
    }

    return ints.toOwnedSlice();
}

test "split ints" {
    var allocator = std.testing.allocator;

    const txt = "123\n456\n";
    const ints = try splitToInts(u16, allocator, txt, "\n");
    defer allocator.free(ints);

    std.testing.expectEqualSlices(u16, &[_]u16{123, 456}, ints);
}

// *****************************************************************************

pub fn HashSet(comptime K: type) type {
    return std.HashMap(
       K, void, 
       hash_map.getAutoHashFn(K), 
       hash_map.getAutoEqlFn(K), 
       hash_map.DefaultMaxLoadPercentage
    );
}

// *****************************************************************************

pub fn xor(a: bool, b: bool) bool {
    return (a and !b) or (b and !a);
}

// *****************************************************************************
/// inspired by: https://github.com/ziglang/zig/issues/793
pub fn EnumArray(comptime T: type, comptime U: type) type {
    return struct {
        data: [std.meta.fields(T).len]U,

        pub fn get(self: *const @This(), tag: T) U {
            return self.data[@enumToInt(tag)];
            // return self.data[std.meta.fieldIndex(T, std.meta.tagName(tag))];
        }

        pub fn set(self: *@This(), tag: T, value: U) void {
            self.data[@enumToInt(tag)] = value;
            // self.data[std.meta.fieldIndex(T, std.meta.tagName(tag))] = value;
        }
    };
}

test "EnumArray" {
    const Weekdays = enum(usize) {
        monday,
        tuesday,
        wednesday, 
        thursday,
        friday
    };

    var map = EnumArray(Weekdays, bool){.data = [_]bool{false} ** std.meta.fields(Weekdays).len};
    std.debug.print("\nEnumArray.get(.monday): {}\n", .{map.get(Weekdays.monday)});
    map.set(.monday, true);
    std.debug.print("\nEnumArray.get(.monday): {}\n", .{map.get(.monday)});

}

// *****************************************************************************

pub fn sort(comptime T: type, allocator: *mem.Allocator, src: []T) !void {
    const aux = try allocator.alloc(T, src.len);
    defer allocator.free(aux);
    radixSort(T, 4, src, aux);
}

/// Sort src. 
pub fn radixSort(comptime T: type, 
                 comptime bits_per_bin: math.Log2Int(T),
                 src: []T,
                 aux: []T
) void {
    const windows = (8 * @sizeOf(T)) / @as(usize, bits_per_bin);

    var i: usize = 0; 
    while (i < windows) : (i += 1) {
        const offset = @intCast(math.Log2Int(T), i * bits_per_bin);
        if (i % 2 == 0) {
            countingSort(T, bits_per_bin, offset, src, aux);
        } else {
            countingSort(T, bits_per_bin, offset, aux, src);
        }
    }

    if (windows % 2 == 1) {
        mem.copy(T, src, aux);
    }
} 

const asc_u32 = std.sort.asc(u32);
test "radix sort" {
    var allocator = std.testing.allocator;

    var src = [_]u32{18, 421, 6, 5888, 1991, 10, 0};

    var src_cpy = try allocator.alloc(u32, src.len);
    defer allocator.free(src_cpy);
    mem.copy(u32, src_cpy[0..], src[0..]);

    std.testing.expectEqualSlices(u32, src[0..], src_cpy[0..]);

    const aux = try allocator.alloc(u32, src.len);
    defer allocator.free(aux);

    radixSort(u32, 4, src[0..], aux[0..]);
    std.sort.sort(u32, src_cpy[0..], {}, asc_u32);

    std.testing.expectEqualSlices(u32, src[0..], src_cpy[0..]);
}

/// Sort src into dst
fn countingSort(comptime T: type,
                comptime bits_per_bin: math.Log2Int(T),
                offset: math.Log2Int(T),
                src: []const T,
                dst: []T
) void {
    const bins = 1 << bits_per_bin;

    // count occurrences of each set/span of bits
    var counts = [_]usize{0} ** bins;
    for (src) |num| {
        counts[bit_span(T, bits_per_bin, offset, num)] += 1;
    }

    // translate counts to their indices in the destination slice.
    // (the counts array will be reused for indices)
    var index: usize = 0;
    for (counts) |*count| {
        const next_index = index + count.*;
        count.* = index;
        index = next_index;
    }

    // insert nums into their cooresponding indices in dst.
    for (src) |num| {
        const span = bit_span(T, bits_per_bin, offset, num);
        const idx = &counts[span]; // destination idx for this number
        dst[idx.*] = num;
        idx.* += 1; // update the index for the next number placement
    }

}

/// Mask out a span of bits
fn bit_span(comptime T: type,
            comptime bits_per_bin: math.Log2Int(T),
            offset: math.Log2Int(T),
            value: T
) meta.Int(.unsigned, bits_per_bin) {
    const BitSpan = meta.Int(.unsigned, bits_per_bin);
    const mask = math.maxInt(BitSpan);
    return @intCast(BitSpan, (value >> offset) & mask);
}

// *****************************************************************************


