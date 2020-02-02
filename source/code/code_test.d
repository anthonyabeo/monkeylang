module code.code_test;

import std.stdio;
import std.typecons;

import code.code;


unittest {
    testMake();
}

/+++/
void testMake() {
    alias Instr = Tuple!(OPCODE, "op", 
                         int[], "operands", 
                         ubyte[], "expected");

    auto tests = [
        Instr(OPCODE.OpConstant, [65_534], [cast(ubyte) OPCODE.OpConstant, 255, 254]),
    ];

    foreach(tt; tests) {
        auto instruction = make(tt.op, tt.operands);
        if(instruction.length != tt.expected.length) {
            stderr.writefln("instruction has wrong length. want=%d, got=%d", tt.expected.length, instruction.length);
            assert(instruction.length == tt.expected.length);
        }

        foreach(i, b; tt.expected) {
            if(instruction[i] != tt.expected[i]) {
                stderr.writeln("wrong byte at pos %d. want=%d, got=%d", i, b, instruction[i]);
                assert(instruction[i] == tt.expected[i]);
            }
        }
    }
}