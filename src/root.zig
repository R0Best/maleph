const std = @import("std");

pub const location = @import("location.zig");
pub const Location = location.Location;

pub const token = @import("token.zig");
pub const Token = token.Token;
pub const enumRaw = token.enumRaw;
pub const StandardTokens = token.StandardTokens;
pub const StandardOperators = token.StandardOperators;
pub const StandardWhitespaces = token.StandardWhitespaces;
pub const StandardNewlines = token.StandardNewlines;

pub const lexer = @import("lexer.zig");
pub const Lexer = lexer.Lexer;
pub const StandardLexer = lexer.StandardLexer;

pub const c8 = u8;

pub const Operation = struct {
    order: std.math.big.int.Managed,
    lhs: *anyopaque,
    rhs: *anyopaque,
};
