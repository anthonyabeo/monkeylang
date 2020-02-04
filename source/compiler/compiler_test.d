module compiler.compiler_test;

import std.stdio;
import std.string;
import std.conv;

import ast.ast;
import code.code;
import lexer.lexer;
import objekt.objekt;
import parser.parser;
import compiler.compiler;


unittest {
    testIntegerArithmetic();
}


/++
 + 
 +/
struct CompilerTestCase(T) {
    string input;                           /// input
    T[] expectedConstants;                  /// expectedConstants
    Instructions[] expectedInstructions;    /// expectedInstructions
}

///
void testIntegerArithmetic() {
    auto tests = [
        CompilerTestCase!int(
            "1 + 2", 
            [1, 2], 
            [
                make(OPCODE.OpConstant, 0), 
                make(OPCODE.OpConstant, 1),
                make(OPCODE.OpAdd),
                make(OPCODE.OpPop),
            ]
        ),
        CompilerTestCase!int(
            "1; 2",
            [1, 2],
            [
                make(OPCODE.OpConstant, 0),
                make(OPCODE.OpPop),
                make(OPCODE.OpConstant, 1),
                make(OPCODE.OpPop),
            ]
        ),
        CompilerTestCase!int(
            "1 - 2",
            [1, 2],
            [
                make(OPCODE.OpConstant, 0),
                make(OPCODE.OpConstant, 1),
                make(OPCODE.OpSub),
                make(OPCODE.OpPop),
            ]
        ),
        CompilerTestCase!int(
            "1 * 2",
            [1, 2],
            [
                make(OPCODE.OpConstant, 0),
                make(OPCODE.OpConstant, 1),
                make(OPCODE.OpMul),
                make(OPCODE.OpPop),
            ]
        ),
        CompilerTestCase!int(
            "2 / 1",
            [2, 1],
            [
                make(OPCODE.OpConstant, 0),
                make(OPCODE.OpConstant, 1),
                make(OPCODE.OpDiv),
                make(OPCODE.OpPop),
            ]
        ),
    ];

    runCompilerTests!int(tests);
}

///
void runCompilerTests(T) (CompilerTestCase!(T)[] tests) {
    foreach (tt; tests) {
        auto program = parse(tt.input);
        auto compiler = Compiler();

        auto err = compiler.compile(program);
        if(err !is null) {
            stderr.writefln("compiler error: %s", err.msg);
            assert(err is null);
        }
        
        auto bytecode = compiler.bytecode();
        
        err = testInstructions(tt.expectedInstructions, bytecode.instructions);
        if(err !is null) {
            stderr.writefln("testInstructions failed: %s", err.msg);
            assert(err is null);
        }

        err = testConstants!int(tt.expectedConstants, bytecode.constants);
        if(err !is null) {
            stderr.writefln("testConstants failed: %s", err.msg);
            assert(err is null);
        }
    }
}

/+++/
Program parse(string input) {
    auto lex = Lexer(input);
    auto parser = Parser(lex);

    return parser.parseProgram();
}

///
Error testInstructions(Instructions[] expected, Instructions actual) {
    auto concatted = concatInstructions(expected);
    if (actual.length != concatted.length)
        return new Error(format("wrong instructions length.\nwant=%s\ngot =%s", concatted, actual));
    
    foreach(i, ins; concatted) {
        if(actual[i] != ins)
            return new Error(format("wrong instruction at %d.\nwant=%s\ngot =%s", 
                                        i, concatted, actual));
    }

    return null;
}

/+++/
Instructions concatInstructions(Instructions[] s) {
    Instructions output = [];
    foreach(ins; s) {
        output ~= ins;
    }

    return output;
}

/+++/
Error testConstants(T) (T[] expected, Objekt[] actual) {
    if(expected.length != actual.length) {
        return new Error(format("wrong number of constants. got=%d, want=%d",
                            actual.length, expected.length));
    }

    foreach(i, constant; expected) {
        switch (to!string(typeid(constant))) {
            case "int":
                auto err = testIntegerObject(to!long(constant), actual[i]);
                if(err !is null)
                    return new Error(format("constant %d - testIntegerObject failed: %s", i, err.msg));
                
                break;
            default:
                break;
        }
    }

    return null;
}

///
Error testIntegerObject(long expected, Objekt actual) {
    auto result = cast(Integer) actual;
    if(result is null)
        return new Error(format("object is not Integer. got=%s (%s)", actual, actual));

    if(result.value != expected)
        return new Error(format("object has wrong value. got=%d, want=%d", result.value, expected));

    return null;   
}