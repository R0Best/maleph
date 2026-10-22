const std = @import("std");
const location_mod = @import("location.zig");
const token_mod = @import("token.zig");

pub const Location = location_mod.Location;
pub const Token = token_mod.Token;
pub const enumRaw = token_mod.enumRaw;
pub const StandardTokens = token_mod.StandardTokens;
pub const StandardOperators = token_mod.StandardOperators;
pub const StandardWhitespaces = token_mod.StandardWhitespaces;
pub const StandardNewlines = token_mod.StandardNewlines;

/// Reference implementation illustrating how custom Enums
/// (`Tokens`, `Operators`, `Whitespaces`, `Newlines`) are defined and resolved by `Lexer`.
///
/// By default, `enumRaw` uses `@tagName(tag)` to obtain the literal string of an enum tag.
/// Define `pub fn raw(self: @This()) []const u8` ONLY when you want symbolic/descriptive enum
/// tag names (e.g. `.colon` instead of `@":"`) that map to a different underlying lexeme string.
const SentinelDocumentation = struct {
    const CustomTokens = enum {
        system,
        atom,
        null,
    };

    const CustomOperators = enum {
        colon,
        assign,
        open_brace,
        close_brace,
        dot,

        pub fn raw(self: @This()) []const u8 {
            return switch (self) {
                .colon => ":",
                .assign => "=",
                .open_brace => "{",
                .close_brace => "}",
                .dot => ".",
            };
        }
    };

    const CustomLexer = Lexer(
        CustomTokens,
        CustomOperators,
        StandardWhitespaces,
        StandardNewlines,
    );
};

comptime {
    _ = SentinelDocumentation;
}

pub const StandardLexer = Lexer(
    StandardTokens,
    StandardOperators,
    StandardWhitespaces,
    StandardNewlines,
);

pub fn Lexer(
    comptime lexer_tokens: type,
    comptime lexer_operators: type,
    comptime lexer_whitespaces: type,
    comptime lexer_newlines: type,
) type {
    return struct {
        pub const Self = @This();
        pub const Tokens = lexer_tokens;
        pub const Operators = lexer_operators;
        pub const Whitespaces = lexer_whitespaces;
        pub const Newlines = lexer_newlines;
        pub const TokenType = Token(Tokens, Operators);

        raw: []const u8,
        location: Location = .{},

        const tokens_map = initTokensMap();
        const operators = sortedValues(Operators);
        const whitespaces = sortedValues(Whitespaces);
        const newlines = sortedValues(Newlines);

        pub fn init(raw: []const u8) Self {
            return .{ .raw = raw };
        }

        pub fn peekToken(self: *const Self) ?TokenType {
            var copy = self.*;
            return copy.nextToken();
        }

        pub fn nextToken(self: *Self) ?TokenType {
            self.skipTrivia();

            if (self.location.index >= self.raw.len) {
                return null;
            }

            if (Self.matchOperator(self.remaining())) |operator| {
                return self.emit(enumRaw(Operators, operator), .{ .operator = operator });
            }

            const word = Self.matchWord(self.remaining()) orelse unreachable;
            const kind: TokenType.Kind = if (Self.exactToken(word)) |token|
                .{ .token = token }
            else
                .identifier;

            return self.emit(word, kind);
        }

        fn skipTrivia(self: *Self) void {
            while (self.location.index < self.raw.len) {
                if (Self.matchNewline(self.remaining())) |newline| {
                    self.location.advanceLine(enumRaw(Newlines, newline));
                } else if (Self.matchWhitespace(self.remaining())) |whitespace| {
                    self.location.advance(enumRaw(Whitespaces, whitespace));
                } else {
                    break;
                }
            }
        }

        fn emit(self: *Self, raw: []const u8, kind: TokenType.Kind) TokenType {
            const token_location = self.location;
            self.location.advance(raw);
            return .{
                .raw = raw,
                .kind = kind,
                .location = token_location,
            };
        }

        fn remaining(self: Self) []const u8 {
            return self.raw[self.location.index..];
        }

        fn initTokensMap() std.StaticStringMap(Tokens) {
            comptime {
                const values = std.enums.values(Tokens);
                var kvs: [values.len]struct { []const u8, Tokens } = undefined;
                for (values, 0..) |tag, i| {
                    kvs[i] = .{ enumRaw(Tokens, tag), tag };
                }
                return std.StaticStringMap(Tokens).initComptime(kvs);
            }
        }

        fn sortedValues(comptime E: type) [std.enums.values(E).len]E {
            comptime {
                const values = std.enums.values(E);
                var result: [values.len]E = values.*;
                var i: usize = 1;
                while (i < result.len) : (i += 1) {
                    const key = result[i];
                    const key_len = enumRaw(E, key).len;
                    var j: usize = i;
                    while (j > 0 and enumRaw(E, result[j - 1]).len < key_len) : (j -= 1) {
                        result[j] = result[j - 1];
                    }
                    result[j] = key;
                }
                return result;
            }
        }

        fn matchPrefix(comptime E: type, comptime values: []const E, raw: []const u8) ?E {
            inline for (values) |tag| {
                const tag_raw = comptime enumRaw(E, tag);
                if (std.mem.startsWith(u8, raw, tag_raw)) {
                    return tag;
                }
            }
            return null;
        }

        fn matchWhitespace(raw: []const u8) ?Whitespaces {
            return Self.matchPrefix(Whitespaces, &Self.whitespaces, raw);
        }

        fn matchNewline(raw: []const u8) ?Newlines {
            return Self.matchPrefix(Newlines, &Self.newlines, raw);
        }

        fn matchOperator(raw: []const u8) ?Operators {
            return Self.matchPrefix(Operators, &Self.operators, raw);
        }

        fn exactToken(raw: []const u8) ?Tokens {
            return Self.tokens_map.get(raw);
        }

        fn matchWord(raw: []const u8) ?[]const u8 {
            var len: usize = 0;
            while (len < raw.len) {
                const slice = raw[len..];
                if (Self.matchWhitespace(slice) != null or
                    Self.matchNewline(slice) != null or
                    Self.matchOperator(slice) != null)
                {
                    break;
                }
                len += location_mod.codepointByteLength(slice);
            }

            if (len == 0) {
                return null;
            }

            return raw[0..len];
        }
    };
}
