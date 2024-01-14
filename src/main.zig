const std = @import("std");
const hashcash = @import("hashcash.zig");
const quotes = @import("quotes.zig");

const net = std.net;
const thread = std.Thread;

const PORT = 63685;
const ADDR = "127.0.0.1";

var gpa = std.heap.GeneralPurposeAllocator(.{}){};
pub const allocator = gpa.allocator();

pub fn main() !void {
    const client1_thread = try thread.spawn(.{}, client, .{});
    client1_thread.detach();

    // const client2_thread = try thread.spawn(.{}, client, .{});
    // client2_thread.detach();

    var server = net.StreamServer.init(.{});
    defer server.deinit();

    try server.listen(net.Address.parseIp(ADDR, PORT) catch unreachable);
    std.debug.print("listening at {}\n", .{server.listen_address});

    while (true) {
        var conn = try server.accept();
        const handle = try thread.spawn(.{}, handle_accept, .{conn});
        handle.detach();
    }
}

fn handle_accept(conn: net.StreamServer.Connection) !void {
    std.debug.print("Connection received! {}.\n", .{conn.address});
    while (true) {
        std.time.sleep(std.time.ns_per_s * 1);
        const message = try conn.stream.reader().readAllAlloc(allocator, 1000);
        if (message.len == 0) { // bad stuff
            std.debug.print("skip\n", .{});
            allocator.free(message);
            continue;
        }
        std.debug.print("{} says {s}\n", .{ conn.address, message });

        if (hashcash.process(message)) |is_valid| {
            if (!is_valid) {
                std.debug.print("Send reject\n", .{});
                try conn.stream.writer().writeAll("REJECTED");
                conn.stream.close();
                return;
            }
        } else |err| {
            std.debug.print("Error during processing: {any}\n", .{err});
            try conn.stream.writer().writeAll("REJECTED");
            conn.stream.close();
            return;
        }
        allocator.free(message);

        std.debug.print("server:OK \n", .{});
        try conn.stream.writer().writeAll(quotes.get_random_quote());
        conn.stream.close();
        return;
    }
}

fn client() !void {
    std.time.sleep(std.time.ns_per_s * 4);

    const peer = try net.Address.parseIp(ADDR, PORT);
    const stream = try net.tcpConnectToAddress(peer);
    // defer stream.close();

    // std.time.sleep(std.time.ns_per_s * 4);
    // while (true) {
    try stream.writer().writeAll("1:20:130124:anni@cypherspace.org:2:1QTjaYd7niiQA/sc:ePa");
    std.debug.print("Sending  to peer, total written:  bytes\n", .{});
    // const message = try stream.reader().readAllAlloc(allocator, 1000);
    // std.debug.print("server says {s}\n", .{  message });
    // }
}
