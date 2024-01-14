const std = @import("std");
const main = @import("main.zig");

var quotes = std.ArrayList([] const u8).init(main.allocator);
var _ = quotes.append("random quote");


var rnd = std.rand.DefaultPrng.init(228);

pub fn get_random_quote() [] const u8{
    var r = @mod(rnd.random().int(u8), quotes.items.len);
    return quotes.items[r];
}