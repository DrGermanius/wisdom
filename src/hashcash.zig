const std = @import("std");
const main = @import("main.zig");

// 8 Apr 2006
// "1:20:130124:anni@cypherspace.org:2:1QTjaYd7niiQA/sc:ePa"
const header_pattern = "{d}:{d}:{s}:{s}:{d}:{s}:{s}";
const fields_count = 7;

var allowed_emails = std.StringHashMap(void).init(main.allocator);
var _ = allowed_emails.put("anni@cypherspace.org", {});

var used_hashes = std.StringHashMap(void).init(main.allocator);

const Header = struct {
    ver: u8,
    bits: u8,
    date: []const u8,
    resource: []const u8,
    ext: u8,
    rand: []const u8,
    counter: []const u8,

    fn to_string(self: *const Header) ![]u8 {
        var buf: [2048]u8 = undefined;
        var b = try std.fmt.bufPrint(&buf, header_pattern, .{ self.ver, self.bits, self.date, self.resource, self.ext, self.rand, self.counter });
        return b;
    }

    fn to_sha1(self: *const Header) !*[20]u8 {
        var buf: [20]u8 = undefined;
        std.crypto.hash.Sha1.hash(try self.to_string(), &buf, .{});
        return &buf;
    }

    const bound_sec = 1172900 + 2 * std.time.s_per_day * 2;
    const sec_unix = 62128598400;
    fn check_date(self: *const Header) !bool {
        var time_sec: i64 = -sec_unix;

        const day = try std.fmt.parseInt(i64, self.date[0..2], 10);
        time_sec += day * std.time.s_per_day;

        const month = try std.fmt.parseInt(i64, self.date[2..4], 10);
        time_sec += month * std.time.s_per_day * 30;

        const year = try std.fmt.parseInt(i64, self.date[4..6], 10);
        time_sec += (year + 2000) * std.time.s_per_day * 365;

        return std.time.timestamp() - time_sec < bound_sec and std.time.timestamp() - time_sec > -1 * bound_sec;
    }

    fn check_bits(self: *const Header) !bool {
        var sha1 = try self.to_sha1();

        var bytes = self.bits / 8;
        var bits = self.bits % 8;

        var i: usize = 0;
        while (i < bytes) : (i += 1) {
            if (sha1[i] != 0) {
                return false;
            }
        }

        var mask: u8 = switch (bits) {
            0 => 0x00,
            1 => 0x01,
            2 => 0x03,
            3 => 0x07,
            4 => 0x0f,
            5 => 0x1f,
            6 => 0x3f,
            7 => 0x7f,
            else => unreachable,
        };

        return sha1[bytes + 1] & mask == 0;
    }
};

pub fn process(str: []const u8) !bool {
    var iter = std.mem.split(u8, str, ":");
    //need to check count of fields

    var header: Header = undefined;
    header.ver = try std.fmt.parseInt(u8, iter.next().?, 10);
    header.bits = try std.fmt.parseInt(u8, iter.next().?, 10);
    header.date = iter.next().?;
    header.resource = iter.next().?;
    header.ext = try std.fmt.parseInt(u8, iter.next().?, 10);
    header.rand = iter.next().?;
    header.counter = iter.next().?;

    if (used_hashes.contains(try header.to_string())){
        return false;
    }

    if (!allowed_emails.contains(header.resource)) {
        return false;
    }

    if (! try header.check_date()) {
        return false;
    }

    if (! try header.check_bits()) {
        return false;
    }

    try used_hashes.put(try header.to_string(), {});
    return true;
}