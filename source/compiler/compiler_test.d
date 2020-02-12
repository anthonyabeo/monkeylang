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
import compiler.symbol_table;


unittest {
    testIntegerArithmetic();
    testBooleanExpressions();
    testConditionals();
    testGlobalLetStatements();
    testStringExpressions();
    testArrayLiterals();
    testHashLiterals();
    testIndexExpressions();
    testFunctions();
    testCompilerScopes();
    testFunctionCalls();
    testLetStatementScopes();
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
        Objekt[] constants;
        auto symTable = new SymbolTable(null);

        auto program = parse(tt.input);
        auto compiler = Compiler(symTable, constants);

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
                                        i, asString(concatted), asString(actual)));
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

alias Foo = Tuple!(int, int, Instructions[]);
///
void testFunctions() {
    auto tests = [
        CompilerTestCase!Foo(
            `fn() { return 5 + 10 }`,
            [
                tuple(
                    5, 10,
                    [
                        make(OPCODE.OpConstant, 0),
                        make(OPCODE.OpConstant, 1),
                        make(OPCODE.OpAdd),
                        make(OPCODE.OpReturnValue),
                    ]
                ),
            ],
            [
                make(OPCODE.OpConstant, 2),
                make(OPCODE.OpPop),
            ]
        ),
        CompilerTestCase!Foo(
            `fn() { 5 + 10 }`,
            [
                tuple(
                    5, 10,
                    [
                        make(OPCODE.OpConstant, 0),
                        make(OPCODE.OpConstant, 1),
                        make(OPCODE.OpAdd),
                        make(OPCODE.OpReturnValue),
                    ]
                ),
            ],
            [
                make(OPCODE.OpConstant, 2),
                make(OPCODE.OpPop),
            ]
        ),
        CompilerTestCase!Foo(
            `fn() { 1; 2 }`,
            [
                tuple(
                    1, 2,
                    [
                        make(OPCODE.OpConstant, 0),
                        make(OPCODE.OpPop),
                        make(OPCODE.OpConstant, 1),
                        make(OPCODE.OpReturnValue),
                    ]
                ),
            ],
            [
                make(OPCODE.OpConstant, 2),
                make(OPCODE.OpPop),
            ]
        ),
        CompilerTestCase!Foo(
            `fn() { }`,
            [
                tuple(
                    0, 0,
                    [
                        make(OPCODE.OpReturn),
                    ]
                ),
            ],
            [
                make(OPCODE.OpConstant, 0),
                make(OPCODE.OpPop),
            ]
        ),
    ];

    foreach (i, tt; tests) {
        Objekt[] constants;
        auto symTable = new SymbolTable(null);

        auto program = parse(tt.input);
        auto compiler = Compiler(symTable, constants);

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

        err = testFunctionConstants(tt.expectedConstants[0][2], bytecode.constants);
        if(err !is null) {
            stderr.writefln("testConstants failed: %s", err.msg);
            assert(err is null);
        }
    }
}

///
Error testFunctionConstants(Instructions[] expected, Objekt[] actual) {
    foreach(constant; actual) {
        auto nde = to!string(typeid((cast(Object) constant)));
        if(nde == "objekt.objekt.CompiledFunction") {
            auto fn = cast(CompiledFunction) constant;
            if(fn is null) 
                return new Error(format("constant - not a function: %s", constant));

            auto err = testInstructions(expected, fn.instructions);
            if(err !is null)
                return new Error(format("constant - testInstructions failed: %s", err));
        }
    }
    
    return null;
}

///
void testCompilerScopes() {
    Objekt[] constants;
    auto symTable = new SymbolTable(null);

    auto compiler = Compiler(symTable, constants);
    if (compiler.scopeIndex != 0) {
        stderr.writefln("scopeIndex wrong. got=%d, want=%d", compiler.scopeIndex, 0);
        assert(compiler.scopeIndex == 0);
    }
    auto globalSymbolTable = compiler.symTable;

    compiler.emit(OPCODE.OpMul);

    compiler.enterScope();
    if (compiler.scopeIndex != 1) {
        stderr.writefln("scopeIndex wrong. got=%d, want=%d", compiler.scopeIndex, 1);
        assert(compiler.scopeIndex == 1);
    }

    compiler.emit(OPCODE.OpSub);

    if(compiler.scopes[compiler.scopeIndex].instructions.length != 1) {
        stderr.writefln("instructions length wrong. got=%d",
                compiler.scopes[compiler.scopeIndex].instructions.length);
        assert(compiler.scopes[compiler.scopeIndex].instructions.length == 1);
    }

    auto last = compiler.scopes[compiler.scopeIndex].lastInstruction;
    if (last.opcode != OPCODE.OpSub) {
        stderr.writefln("lastInstruction.Opcode wrong. got=%d, want=%d", last.opcode, OPCODE.OpSub);
        assert(last.opcode == OPCODE.OpSub);
    }

    if(compiler.symTable.outer !is globalSymbolTable) {
        stderr.writefln("compiler did not enclose symbolTable");
        assert(compiler.symTable.outer is globalSymbolTable);
    }

    compiler.leaveScope();
    if (compiler.scopeIndex != 0) {
        stderr.writefln("scopeIndex wrong. got=%d, want=%d", compiler.scopeIndex, 0);
        assert(compiler.scopeIndex == 0);
    }

    if(compiler.symTable !is globalSymbolTable) {
        stderr.writefln("compiler did not restore global symbol table");
        assert(compiler.symTable is globalSymbolTable);
    }

    if(compiler.symTable.outer !is null) {
        stderr.writefln("compiler modified global symbol table incorrectly");
        assert(compiler.symTable.outer is null);
    }

    compiler.emit(OPCODE.OpAdd);

    if (compiler.scopes[compiler.scopeIndex].instructions.length != 2) {
        stderr.writefln("instructions length wrong. got=%d", compiler.scopes[compiler.scopeIndex].instructions.length);
        assert(compiler.scopes[compiler.scopeIndex].instructions.length == 2);
    }

    last = compiler.scopes[compiler.scopeIndex].lastInstruction;
    if(last.opcode != OPCODE.OpAdd) {
        stderr.writefln("lastInstruction.Opcode wrong. got=%d, want=%d", last.opcode, OPCODE.OpAdd);
        assert(last.opcode == OPCODE.OpAdd);
    }

    auto previous = compiler.scopes[compiler.scopeIndex].previousInstruction;
    if (previous.opcode != OPCODE.OpMul) {
        stderr.writefln("previousInstruction.Opcode wrong. got=%d, want=%d", previous.opcode, OPCODE.OpMul);
        assert(previous.opcode == OPCODE.OpMul);
    }
}

///
void testFunctionCalls() {
    auto tests = [
        CompilerTestCase!Foo(
            `fn() { 24 }();`,
            [
                tuple(
                    0, 24,
                    [
                        make(OPCODE.OpConstant, 0), // The literal "24"
                        make(OPCODE.OpReturnValue),
                    ]
                ),
            ],
            [
                make(OPCODE.OpConstant, 1), // The compiled function
                make(OPCODE.OpCall),
                make(OPCODE.OpPop),
            ]
        ),

        CompilerTestCase!Foo(
            `let noArg = fn() { 24 };
             noArg();`,
             [
                 tuple(
                    0, 24,
                    [
                        make(OPCODE.OpConstant, 0), // The literal "24"
                        make(OPCODE.OpReturnValue),
                    ]
                 ),
             ],
             [
                make(OPCODE.OpConstant, 1), // The compiled function
                make(OPCODE.OpSetGlobal, 0),
                make(OPCODE.OpGetGlobal, 0),
                make(OPCODE.OpCall),
                make(OPCODE.OpPop),
             ]
        ),
    ];

    foreach (i, tt; tests) {
        Objekt[] constants = [];        
        auto symTable = new SymbolTable(null);

        auto program = parse(tt.input);
        auto compiler = Compiler(symTable, constants);

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

        err = testFunctionConstants(tt.expectedConstants[0][2], bytecode.constants);
        if(err !is null) {
            stderr.writefln("testConstants failed: %s", err.msg);
            assert(err is null);
        }
    }
}

void testLetStatementScopes() {
    auto tests = [
        CompilerTestCase!Foo(
            `let num = 55;fn() { num }`,
            [
                tuple(
                    0, 55,
                    [
                        make(OPCODE.OpGetGlobal, 0),
                        make(OPCODE.OpReturnValue),
                    ]
                ),
            ],
            [
                make(OPCODE.OpConstant, 0),
                make(OPCODE.OpSetGlobal, 0),
                make(OPCODE.OpConstant, 1),
                make(OPCODE.OpPop),
            ]
        ),
        CompilerTestCase!Foo(
            `fn() {let num = 55;num}`,
            [
                tuple(
                    0, 55,
                    [
                        make(OPCODE.OpConstant, 0),
                        make(OPCODE.OpSetLocal, 0),
                        make(OPCODE.OpGetLocal, 0),
                        make(OPCODE.OpReturnValue),
                    ]
                ),
            ],
            [
                make(OPCODE.OpConstant, 1),
                make(OPCODE.OpPop),
            ]
        ),
        CompilerTestCase!Foo(
            `fn() {let a = 55;let b = 77;a + b}`,
            [
                tuple(
                    55, 77,
                    [
                        make(OPCODE.OpConstant, 0),
                        make(OPCODE.OpSetLocal, 0),
                        make(OPCODE.OpConstant, 1),
                        make(OPCODE.OpSetLocal, 1),
                        make(OPCODE.OpGetLocal, 0),
                        make(OPCODE.OpGetLocal, 1),
                        make(OPCODE.OpAdd),
                        make(OPCODE.OpReturnValue),
                    ]
                )
            ],
            [
                make(OPCODE.OpConstant, 2),
                make(OPCODE.OpPop),
            ]
        ),
    ];

    foreach (i, tt; tests) {
        Objekt[] constants = [];        
        auto symTable = new SymbolTable(null);

        auto program = parse(tt.input);
        auto compiler = Compiler(symTable, constants);

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

        err = testFunctionConstants(tt.expectedConstants[0][2], bytecode.constants);
        if(err !is null) {
            stderr.writefln("testConstants failed: %s", err.msg);
            assert(err is null);
        }
    }
}