const std = @import("std");
const maleph = @import("maleph");
const Lexer = maleph.StandardLexer;

pub fn main(init: std.process.Init) !void {
    const io = init.io;

    var args = try std.process.Args.Iterator.initAllocator(init.minimal.args, init.gpa);
    defer args.deinit();

    _ = args.skip();
    const file_path = args.next() orelse return error.MissingFileArgument;

    const raw = try std.Io.Dir.cwd().readFileAlloc(io, file_path, init.gpa, .unlimited);
    defer init.gpa.free(raw);

    var lexer: Lexer = .init(raw);

    while (lexer.nextToken()) |token| {
        std.debug.print("{s}:{f}\n", .{ file_path, token });
    }
}
