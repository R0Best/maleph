const std = @import("std");
const Location = @import("location.zig").Location;

/// Resolves the string representation of an enum tag.
/// Uses `E.raw(tag)` if the enum declares a custom `pub fn raw`, or `@tagName(tag)` otherwise.
pub fn enumRaw(comptime E: type, tag: E) []const u8 {
    if (@hasDecl(E, "raw")) {
        return tag.raw();
    }
    return @tagName(tag);
}

/// Generic token parameterized over keyword `Tokens` and delimiter `Operators` enums.
pub fn Token(comptime Tokens: type, comptime Operators: type) type {
    return struct {
        pub const Self = @This();

        pub const Kind = union(enum) {
            token: Tokens,
            operator: Operators,
            identifier,
        };

        raw: []const u8,
        kind: Kind,
        location: Location,

        pub fn format(self: Self, writer: *std.Io.Writer) std.Io.Writer.Error!void {
            try writer.print("{f}: {s} ({any})", .{ self.location, self.raw, self.kind });
        }
    };
}

/// Standard language keywords matched by exact full-word equality (`std.StaticStringMap`).
/// Tag names match their exact source lexemes via `@tagName`; define `pub fn raw(self: @This()) []const u8`
/// only if an enum tag name needs to differ from its source representation.
pub const StandardTokens = enum {
    // Types & Entities
    @"\\System",
    @"\\Atom",
    @"\\Null",
    @"\\Operator",
    @"\\Property",
    @"\\Identity",

    // Declarations & Definitions
    @"\\define",
    @"\\where",
    @"\\as",
    @"\\being",
    @"\\of_type",

    // Predicates & Domain Relations
    @"\\is_apart_of",
    @"\\and_also",
    @"\\domain_of",
    @"\\equality",

    // Block Delimiters
    @"\\block_begin",
    @"\\block_end",

    // Expression Delimiters
    @"\\expression_begin",
    @"\\expression_end",

    // Set Delimiters & Operations
    @"\\set_begin",
    @"\\set_end",
    @"\\set_subtraction",

    // Operations
    @"\\hyperoperation",

    // Instruction Terminators
    @"\\instruction_end",
};

/// Standard punctuation/operator delimiters matched by longest prefix first.
/// Tag names match their exact source lexemes via `@tagName`; define `pub fn raw(self: @This()) []const u8`
/// only if an enum tag name needs to differ from its source representation.
pub const StandardOperators = enum {
    @":",
    @"=",
    @"{",
    @"}",
    @"(",
    @")",
    @",",
    @".",
    @";",
};

/// Standard horizontal whitespace sequences matched by longest prefix first.
pub const StandardWhitespaces = enum {
    @" ",
    @"\t",
};

/// Standard line-ending sequences matched by longest prefix first.
pub const StandardNewlines = enum {
    @"\r\n",
    @"\r",
    @"\n",
};
