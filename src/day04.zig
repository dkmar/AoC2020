const std = @import("std");
const Allocator = std.mem.Allocator;
const assert = std.debug.assert;
const print = std.debug.print;
const util = @import("utils.zig");
const input = @embedFile("../in/day04.txt");


const PassportField = enum(usize) {
    byr = 0,
    iyr = 1,
    eyr = 2,
    hgt = 3,
    hcl = 4,
    ecl = 5,
    pid = 6,
    cid = 7
};

pub fn main() !void {
    const n_fields = std.meta.fields(PassportField).len;
    const map = std.ComptimeStringMap(PassportField, .{
        .{"byr", .byr},
        .{"iyr", .iyr},
        .{"eyr", .eyr},
        .{"hgt", .hgt},
        .{"hcl", .hcl},
        .{"ecl", .ecl},
        .{"pid", .pid},
        .{"cid", .cid}}
    );

    var valid: u16 = 0;
    var it = std.mem.split(input, "\n\n");
    while (it.next()) |passport| {
        var is_present = [_]bool{false} ** n_fields;
        var fields_present: u8 = 0;
        var field_it = std.mem.tokenize(passport, ": \n");
        while (field_it.next()) |field| {
            if (map.get(field)) |field_tag| {
                if (is_present[@enumToInt(field_tag)] == false) {
                    is_present[@enumToInt(field_tag)] = true;
                    fields_present += 1;
                }
            }
            _ = field_it.next(); // skip rhs of colon for this field.
        }
        if (fields_present == n_fields or 
            (fields_present == (n_fields-1) and is_present[@enumToInt(PassportField.cid)] == false)) {
            valid += 1;
        }
    }

    print("part1: {}", .{valid});
}
