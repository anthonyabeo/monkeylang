module code.code_test;

import std.stdio;
import std.typecons;
import std.string;

import code.code;


unittest {
    testMake();
    testInstructionString();
    testReadOperands();
}

/+++/
void testMake() {
    alias Instr = Tuple!(OPCODE, "op", 
                         size_t[], "operands", 
                         ubyte[], "expected");

    auto tests = [
        Instr(OPCODE.OpConstant, [65_534], [cast(ubyte) OPCODE.OpConstant, 255, 254]),
        Instr(OPCODE.OpAdd, [], [cast(byte) OPCODE.OpAdd]),
        Instr(OPCODE.OpGetLocal, [255], [cast(ubyte) OPCODE.OpGetLocal, 255]),
    ];

    foreach(tt; tests) {
        auto instruction = make(tt.op, tt.operands);
        if(instruction.length != tt.expected.length) {
            stderr.writefln("instruction has wrong length. want=%d, got=%d", 
                                tt.expected.length, instruction.length);
            assert(instruction.length == tt.expected.length);
        }

        foreach(i, b; tt.expected) {
            if(instruction[i] != tt.expected[i]) {
                stderr.writefln("wrong byte at pos %d. want=%d, got=%d", 
                                    i, b, instruction[i]);
                assert(instruction[i] == tt.expected[i]);
            }
        }
    }
}

///
void testInstructionString() {
    auto instructions = [
        make(OPCODE.OpAdd),
        make(OPCODE.OpGetLocal, 1),
        make(OPCODE.OpConstant, 2),
        make(OPCODE.OpConstant, 65_535),
    ];

    auto expected = `0000 OpAdd
0001 OpGetLocal 1
0003 OpConstant 2
0006 OpConstant 65535
`;

    Instructions concatted = [];
    foreach(ins; instructions) {
        concatted ~= ins;
    }

    if(asString(concatted) != expected)
        stderr.writefln("instructions wrongly formatted.\nwant=%s\ngot=%s", 
                         expected, asString(concatted));
        assert(asString(concatted) == expected);
}

///
void testReadOperands() {
    alias ReadOp = Tuple!(Opcode, "op",
                         size_t[], "operands",
                         int, "bytesRead");

    auto tests = [
        ReadOp(OPCODE.OpConstant, [65_535], 2),
        ReadOp(OPCODE.OpGetLocal, [255], 1),
    ];

    foreach(tt; tests) {
        auto instruction = make(tt.op, tt.operands);

        auto def = lookUp(cast(ubyte) tt.op);
        if(def is null)
            stderr.writefln("definition not found: %q\n", def);
            assert(def !is null);

        auto result = readOperands(def, instruction[1..$]);
        auto operandsRead = result[0], n = result[1];
        if(n != tt.bytesRead) {
            stderr.writefln("n wrong. want=%d, got=%d", tt.bytesRead, n);
            assert(n == tt.bytesRead);
        }

        foreach(i, want; tt.operands) {
            if(operandsRead[i] != want) {
                stderr.writefln("operand wrong. want=%d, got=%d", want, operandsRead[i]);
            }
        }
    }

}