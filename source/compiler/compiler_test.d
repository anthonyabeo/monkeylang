module compiler.compiler_test;

import std.stdio;
import std.string;
import std.conv;
import std.typecons;

import ast.ast;
import code.code;
import lexer.lexer;
import objekt.objekt;
import parser.parser;
import compiler.compiler;


unittest {
    testIntegerArithmetic();
    testBooleanExpressions();
    testConditionals();
    testGlobalLetStatements();
    testStringExpressions();
    testArrayLiterals();
    testHashLiterals();
    testIndexExpressions();
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
        CompilerTestCase!int(
            "-1",
            [1],
            [
                make(OPCODE.OpConstant, 0),
                make(OPCODE.OpMinus),
                make(OPCODE.OpPop),
            ]
        ),
    ];

    runCompilerTests!int(tests);
}

///
void testBooleanExpressions() {
    auto tests = [
        CompilerTestCase!int(
            "1 > 2",
            [1, 2],
            [
                make(OPCODE.OpConstant, 0),
                make(OPCODE.OpConstant, 1),
                make(OPCODE.OpGreaterThan),
                make(OPCODE.OpPop),
            ]     
        ),
        CompilerTestCase!int(
            "1 < 2",
            [2, 1],
            [
                make(OPCODE.OpConstant, 0),
                make(OPCODE.OpConstant, 1),
                make(OPCODE.OpGreaterThan),
                make(OPCODE.OpPop),
            ]
        ),
        CompilerTestCase!int(
            "1 == 2",
            [1, 2],
            [
                make(OPCODE.OpConstant, 0),
                make(OPCODE.OpConstant, 1),
                make(OPCODE.OpEqual),
                make(OPCODE.OpPop),
            ]
        ),
        CompilerTestCase!int(
            "1 != 2",
            [1, 2],
            [
                make(OPCODE.OpConstant, 0),
                make(OPCODE.OpConstant, 1),
                make(OPCODE.OpNotEqual),
                make(OPCODE.OpPop),
            ]
        ),
        CompilerTestCase!int(
            "true == false",
            [],
            [
                make(OPCODE.OpTrue),
                make(OPCODE.OpFalse),
                make(OPCODE.OpEqual),
                make(OPCODE.OpPop),
            ]
        ),
        CompilerTestCase!int(
            "true != false",
            [],
            [
                make(OPCODE.OpTrue),
                make(OPCODE.OpFalse),
                make(OPCODE.OpNotEqual),
                make(OPCODE.OpPop),
            ]
        ),
        CompilerTestCase!int(
            "!true",
            [],
            [
                make(OPCODE.OpTrue),
                make(OPCODE.OpBang),
                make(OPCODE.OpPop),
            ]
        ),
        CompilerTestCase!int(
            "true",
            [],
            [
                make(OPCODE.OpTrue),
                make(OPCODE.OpPop),
            ]
        ),
        CompilerTestCase!int(
            "false",
            [],
            [
                make(OPCODE.OpFalse),
                make(OPCODE.OpPop),
            ]
        ),
    ];

    runCompilerTests!int(tests);
}

///
void testConditionals() {
    auto tests = [
        CompilerTestCase!int(
            `if (true) { 10 }; 3333;`,
            [10, 3333],
            [
                make(OPCODE.OpTrue),                    /// 0000
                make(OPCODE.OpJumpNotTruthy, 10),       /// 0001
                make(OPCODE.OpConstant, 0),             /// 0004
                make(OPCODE.OpJump, 11),                /// 0007
                make(OPCODE.OpNull),                    /// 0010
                make(OPCODE.OpPop),                     /// 0011
                make(OPCODE.OpConstant, 1),             /// 0012
                make(OPCODE.OpPop),                     /// 0015
            ]
        ),
        CompilerTestCase!int(
            `if (true) { 10 } else { 20 }; 3333;`,
            [10, 20, 3333],
            [
                make(OPCODE.OpTrue),                /// 0000
                make(OPCODE.OpJumpNotTruthy, 10),   /// 0001
                make(OPCODE.OpConstant, 0),         /// 0004
                make(OPCODE.OpJump, 13),            /// 0007
                make(OPCODE.OpConstant, 1),         /// 0010
                make(OPCODE.OpPop),                 /// 0013
                make(OPCODE.OpConstant, 2),         /// 0014
                make(OPCODE.OpPop),                 /// 0017
            ]
        ),
    ];

    runCompilerTests!int(tests);
}

///
void runCompilerTests(T) (CompilerTestCase!(T)[] tests) {
    foreach (i, tt; tests) {
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

        err = testConstants!T(tt.expectedConstants, bytecode.constants);
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
        return new Error(format("wrong instructions length.\nwant=%s\ngot =%s", 
                                asString(concatted), asString(actual)));
    
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
            case "immutable(char)[]":
                auto err = testStringObject(to!string(constant), actual[i]);
                if(err !is null)
                    return new Error(format("constant %d - testStringObject failed: %s",i, err.msg));

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

///
void testGlobalLetStatements() {
    auto tests = [
        CompilerTestCase!int(
            `let one = 1; let two = 2;`,
            [1, 2],
            [
                make(OPCODE.OpConstant, 0),
                make(OPCODE.OpSetGlobal, 0),
                make(OPCODE.OpConstant, 1),
                make(OPCODE.OpSetGlobal, 1),
            ]
        ),
        CompilerTestCase!int(
            `let one = 1; one;`,
            [1],
            [
                make(OPCODE.OpConstant, 0),
                make(OPCODE.OpSetGlobal, 0),
                make(OPCODE.OpGetGlobal, 0),
                make(OPCODE.OpPop),
            ]
        ),
        CompilerTestCase!int(
            `let one = 1; let two = one; two;`,
            [1],
            [
                make(OPCODE.OpConstant, 0),
                make(OPCODE.OpSetGlobal, 0),
                make(OPCODE.OpGetGlobal, 0),
                make(OPCODE.OpSetGlobal, 1),
                make(OPCODE.OpGetGlobal, 1),
                make(OPCODE.OpPop),
            ]
        ),
    ];

    runCompilerTests!int(tests);
}

///
void testStringExpressions() {
    auto tests = [
        CompilerTestCase!string(
            `"monkey"`,
            ["monkey"],
            [
                make(OPCODE.OpConstant, 0),
                make(OPCODE.OpPop),
            ]
        ),
        CompilerTestCase!string(
            `"mon" + "key"`,
            ["mon", "key"],
            [
                make(OPCODE.OpConstant, 0),
                make(OPCODE.OpConstant, 1),
                make(OPCODE.OpAdd),
                make(OPCODE.OpPop),
            ]
        ),
    ];

    runCompilerTests!string(tests);
}

///
Error testStringObject(string expected, Objekt actual) {
    auto result = cast(String) actual;
    if(result is null)
        return new Error(format("object is not String. got=%s (%s)", actual, actual));

    if(result.value != expected)
        return new Error(format("object has wrong value. got=%s, want=%s", result.value, expected));

    return null;
}

///
void testArrayLiterals() {
    auto tests = [
        CompilerTestCase!int(
            "[]",
            [],
            [
                make(OPCODE.OpArray, 0),
                make(OPCODE.OpPop),
            ]
        ),
        CompilerTestCase!int(
            "[1, 2, 3]",
            [1, 2, 3],
            [
                make(OPCODE.OpConstant, 0),
                make(OPCODE.OpConstant, 1),
                make(OPCODE.OpConstant, 2),
                make(OPCODE.OpArray, 3),
                make(OPCODE.OpPop),
            ]
        ),
        CompilerTestCase!int(
            "[1 + 2, 3 - 4, 5 * 6]",
            [1, 2, 3, 4, 5, 6],
            [
                make(OPCODE.OpConstant, 0),
                make(OPCODE.OpConstant, 1),
                make(OPCODE.OpAdd),
                make(OPCODE.OpConstant, 2),
                make(OPCODE.OpConstant, 3),
                make(OPCODE.OpSub),
                make(OPCODE.OpConstant, 4),
                make(OPCODE.OpConstant, 5),
                make(OPCODE.OpMul),
                make(OPCODE.OpArray, 3),
                make(OPCODE.OpPop),
            ]
        ),
    ];

    runCompilerTests!int(tests);
}

///
void testHashLiterals() {
    auto tests = [
        CompilerTestCase!int(
            "{}",
            [],
            [
                make(OPCODE.OpHash, 0),
                make(OPCODE.OpPop),
            ]
        ),
        CompilerTestCase!int(
            "{1: 2, 3: 4, 5: 6}",
            [1, 2, 3, 4, 5, 6],
            [
                make(OPCODE.OpConstant, 0),
                make(OPCODE.OpConstant, 1),
                make(OPCODE.OpConstant, 2),
                make(OPCODE.OpConstant, 3),
                make(OPCODE.OpConstant, 4),
                make(OPCODE.OpConstant, 5),
                make(OPCODE.OpHash, 6),
                make(OPCODE.OpPop),
            ]
        ),
        CompilerTestCase!int(
            "{1: 2 + 3, 4: 5 * 6}",
            [1, 2, 3, 4, 5, 6],
            [
                make(OPCODE.OpConstant, 0),
                make(OPCODE.OpConstant, 1),
                make(OPCODE.OpConstant, 2),
                make(OPCODE.OpAdd),
                make(OPCODE.OpConstant, 3),
                make(OPCODE.OpConstant, 4),
                make(OPCODE.OpConstant, 5),
                make(OPCODE.OpMul),
                make(OPCODE.OpHash, 4),
                make(OPCODE.OpPop),
            ]
        ),
    ];

    runCompilerTests(tests);
}

///
void testIndexExpressions() {
    auto tests = [
        CompilerTestCase!int(
            "[1, 2, 3][1 + 1]",
            [1, 2, 3, 1, 1],
            [
                make(OPCODE.OpConstant, 0),
                make(OPCODE.OpConstant, 1),
                make(OPCODE.OpConstant, 2),
                make(OPCODE.OpArray, 3),
                make(OPCODE.OpConstant, 3),
                make(OPCODE.OpConstant, 4),
                make(OPCODE.OpAdd),
                make(OPCODE.OpIndex),
                make(OPCODE.OpPop),
            ]
        ),
        CompilerTestCase!int(
            "{1: 2}[2 - 1]",
            [1, 2, 2, 1],
            [
                make(OPCODE.OpConstant, 0),
                make(OPCODE.OpConstant, 1),
                make(OPCODE.OpHash, 2),
                make(OPCODE.OpConstant, 2),
                make(OPCODE.OpConstant, 3),
                make(OPCODE.OpSub),
                make(OPCODE.OpIndex),
                make(OPCODE.OpPop),
            ]
        ),
    ];

    runCompilerTests!int(tests);
}