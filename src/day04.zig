const std = @import("std");
const mem = std.mem;
const Allocator = mem.Allocator;
const assert = std.debug.assert;
const print = std.debug.print;
const fmt = std.fmt;
const util = @import("utils.zig");
const input = @embedFile("../in/day04.txt");

const PassportField = enum(usize) {
    byr,
    iyr,
    eyr,
    hgt,
    hcl,
    ecl,
    pid,
    cid
};

fn part1(comptime n_fields: usize, map: anytype) void {
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

    print("part1: {}\n", .{valid});
}

fn part2(comptime n_fields: usize, map: anytype) void {
    var valid: u16 = 0;
    var it = mem.split(input, "\n\n");
    while (it.next()) |passport| {
        var is_present = [_]bool{false} ** n_fields;
        var field_it = mem.tokenize(passport, " :\n");
        while (field_it.next()) |field| {
            const field_value = field_it.next().?;
            if (map.get(field)) |field_tag| {
                switch (field_tag) {
                    .byr => if (isValidYear(field_value, 1920, 2002)) markPresent(field_tag, &is_present),
                    .iyr => if (isValidYear(field_value, 2010, 2020)) markPresent(field_tag, &is_present),
                    .eyr => if (isValidYear(field_value, 2020, 2030)) markPresent(field_tag, &is_present),
                    .hgt => if (isValidHeight(field_value)) markPresent(field_tag, &is_present),
                    .hcl => if (isValidHairColor(field_value)) markPresent(field_tag, &is_present),
                    .ecl => if (isValidEyeColor(field_value)) markPresent(field_tag, &is_present),
                    .pid => if (isValidPid(field_value)) markPresent(field_tag, &is_present),
                    .cid => continue
                }
            }
        }
        // count all fields marked present (except for cid which we're ignoring)
        const fields_present = blk: {
            var n: u8 = 0;
            for (is_present[0..@enumToInt(PassportField.cid)]) |s| { if (s) n += 1; }
            break :blk n;
        };

        if (fields_present == (n_fields - 1)) {
            valid += 1;
        }
    }

    print("part2: {}\n", .{valid});
}

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

    part1(n_fields, map);
    part2(n_fields, map);
}

inline fn markPresent(field: PassportField, is_present: []bool) void {
    is_present[@enumToInt(field)] = true;
}

fn isValidYear(buf: []const u8, min: u16, max: u16) bool {
    if (buf.len != 4) return false;
    if (fmt.parseUnsigned(u16, buf, 10)) |year| {
        return (min <= year and year <= max);
    } else |err| {
        return false;
    }
}

fn isValidHeight(buf: []const u8) bool {
    if (buf.len < 4) return false;
    switch (buf[3]) {
        'c' => if (std.fmt.parseUnsigned(u16, buf[0..3], 10)) |height| {
            return (150 <= height and height <= 193);
        } else |err| return false,
        'n' => if (std.fmt.parseUnsigned(u16, buf[0..2], 10)) |height| {
            return (59 <= height and height <= 76);
        } else |err| return false,
        else => return false
    }
}

fn isValidHairColor(buf: []const u8) bool {
    if (buf.len != 7 or buf[0] != '#') return false; 
    for (buf[1..]) |char| {
        if (!(('0' <= char and char <= '9') or ('a' <= char and char <= 'f'))) {
            return false;
        }
    }
    return true;
}

fn isValidEyeColor(buf: []const u8) bool {
    if (buf.len != 3) return false;
    if (mem.eql(u8, buf, "amb") or 
        mem.eql(u8, buf, "blu") or 
        mem.eql(u8, buf, "brn") or 
        mem.eql(u8, buf, "gry") or 
        mem.eql(u8, buf, "grn") or 
        mem.eql(u8, buf, "hzl") or 
        mem.eql(u8, buf, "oth")) {
        return true;
    }
    return false;
}

fn isValidPid(buf: []const u8) bool {
    if (buf.len != 9) return false;
    for (buf) |char| {
        if (!std.ascii.isDigit(char)) return false;
    }
    return true;
}
