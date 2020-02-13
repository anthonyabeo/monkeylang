module vm.vm_test;

import std.stdio;
import std.string;
import std.conv;
import std.typecons;

import vm.vm;
import ast.ast;
import code.code;
import lexer.lexer;
import objekt.objekt;
import parser.parser;
import compiler.compiler;
import evaluator.builtins : NULL;
import compiler.symbol_table;

unittest {
    testIntegerArithmetic();
    testBooleanExpressions();
    testIntegerConditional();
    testNullConditional();
    testGlobalLetStatements();
    testStringExpressions();
    testArrayLiterals();
    testHashLiterals();
    testIntgerIndexExpressions();
    testNullIndexExpressions();
    testCallingFunctionsWithoutArguments();
    testFunctionsWithReturnStatement();
    testFunctionsWithoutReturnValue();
    testFirstClassFunctions();
    testCallingFunctionsWithBindings();
    testFirstClassFunctions();
    testCallingFunctionsWithArgumentsAndBindings();
    testCallingFunctionsWithWrongArguments();
}

///
void testIntegerConditional() {
    auto tests = [
        VMTestCase!int("if (true) { 10 }", 10),
        VMTestCase!int("if (true) { 10 } else { 20 }", 10),
        VMTestCase!int("if (false) { 10 } else { 20 } ", 20),
        VMTestCase!int("if (1) { 10 }", 10),
        VMTestCase!int("if (1 < 2) { 10 }", 10),
        VMTestCase!int("if (1 < 2) { 10 } else { 20 }", 10),
        VMTestCase!int("if (1 > 2) { 10 } else { 20 }", 20),
        VMTestCase!int("if ((if (false) { 10 })) { 10 } else { 20 }", 20),
    ];

    runVMTests!int(tests);
}

///
void testNullConditional() {
    Objekt[] constants = [];        
    Objekt[] globals = new Objekt[GLOBALS_SIZE];
    auto symTable = new SymbolTable(null);

    auto tests = [
        VMTestCase!Null("if (1 > 2) { 10 }", NULL),
        VMTestCase!Null("if (false) { 10 }", NULL),
    ];

    foreach(tt; tests) {
        auto program = parse(tt.input);
        auto compiler = Compiler(symTable, constants);
        auto err = compiler.compile(program);
        if(err !is null) {
            stderr.writefln("compiler error: %s", err.msg);
            assert(err is null);
        }
        
        auto code = compiler.bytecode();
        auto vm = VM(code, globals);
        err = vm.run();
        if(err !is null) {
            stderr.writefln("vm error: %s", err.msg);
            assert(err is null);
        }

        auto stackElem = vm.lastPoppedStackElem();
        testNullObject(stackElem);
    }
}

///
void testBooleanExpressions() {
    auto tests = [
        VMTestCase!bool("true", true),
        VMTestCase!bool("false", false),
        VMTestCase!bool("1 < 2", true),
        VMTestCase!bool("1 > 2", false),
        VMTestCase!bool("1 < 1", false),
        VMTestCase!bool("1 > 1", false),
        VMTestCase!bool("1 == 1", true),
        VMTestCase!bool("1 != 1", false),
        VMTestCase!bool("1 == 2", false),
        VMTestCase!bool("1 != 2", true),
        VMTestCase!bool("true == true", true),
        VMTestCase!bool("false == false", true),
        VMTestCase!bool("true == false", false),
        VMTestCase!bool("true != false", true),
        VMTestCase!bool("false != true", true),
        VMTestCase!bool("(1 < 2) == true", true),
        VMTestCase!bool("(1 < 2) == false", false),
        VMTestCase!bool("(1 > 2) == true", false),
        VMTestCase!bool("(1 > 2) == false", true),
        VMTestCase!bool("!true", false),
        VMTestCase!bool("!false", true),
        VMTestCase!bool("!5", false),
        VMTestCase!bool("!!true", true),
        VMTestCase!bool("!!false", false),
        VMTestCase!bool("!!5", true),
        VMTestCase!bool("!(if (false) { 5; })", true),
    ];

    runVMTests!bool(tests);
}

///
Error testBooleanObject(bool expected, Objekt actual) {
    auto result = cast(Boolean) actual;
    if(result is null) {
        return new Error(format("object is not Boolean. got=%s (%s)",
                            actual, actual));
    }

    if(result.value != expected) {
        return new Error(format("object has wrong value. got=%s, want=%s",
                                   result.value, expected));
    }

    return null;
}

///
void testIntegerArithmetic() {
    auto tests = [
        VMTestCase!int("1", 1),
        VMTestCase!int("2", 2),
        VMTestCase!int("1+2", 3),
        VMTestCase!int("1 - 2", -1),
        VMTestCase!int("1 * 2", 2),
        VMTestCase!int("4 / 2", 2),
        VMTestCase!int("50 / 2 * 2 + 10 - 5", 55),
        VMTestCase!int("5 + 5 + 5 + 5 - 10", 10),
        VMTestCase!int("2 * 2 * 2 * 2 * 2", 32),
        VMTestCase!int("5 * 2 + 10", 20),
        VMTestCase!int("5 + 2 * 10", 25),
        VMTestCase!int("5 * (2 + 10)", 60),
        VMTestCase!int("-5", -5),
        VMTestCase!int("-10", -10),
        VMTestCase!int("-50 + 100 + -50", 0),
        VMTestCase!int("(5 + 10 * 2 + 15 / 3) * 2 + -10", 50),
    ];

    runVMTests!int(tests);
}

///
struct VMTestCase(T) {
    string input;       /// input
    T expected;         /// expected
}

///
void runVMTests(T) (VMTestCase!(T)[] tests) {
    Objekt[] constants = [];        
    Objekt[] globals = new Objekt[GLOBALS_SIZE];
    auto symTable = new SymbolTable(null);

    foreach(tt; tests) {
        auto program = parse(tt.input);
        auto compiler = Compiler(symTable, constants);
        auto err = compiler.compile(program);
        if(err !is null) {
            stderr.writefln("compiler error: %s", err.msg);
            assert(err is null);
        }

        auto code = compiler.bytecode();
        auto vm = VM(code, globals);
        err = vm.run();
        if(err !is null) {
            stderr.writefln("vm error: %s", err.msg);
            assert(err is null);
        }

        auto stackElem = vm.lastPoppedStackElem();
        testExpectedObject!T(tt.expected, stackElem);
    }
}

///
void testNullObject(Objekt actual) {
    if(actual.type() != NULL.type()) {
        stderr.writefln("object is not Null: %s (%s)", actual, actual);
        assert(actual.type() == NULL.type());
    }
}

///
void testExpectedObject(T) (T expected, Objekt actual) {
    switch(to!string(typeid(expected))) {
        case "int":
            auto err = testIntegerObject(to!long(expected), actual);
            if(err !is null) {
                stderr.writefln("testIntegerObject failed: %s", err.msg);
                assert(err is null);
            }
            break;
        case "bool":
            auto err = testBooleanObject(to!bool(expected), actual);
            if(err !is null) {
                stderr.writefln("testBooleanObject failed: %s", err.msg);
                assert(err is null);
            }
            break;
        case "immutable(char)[]":
            auto err = testStringObject(to!string(expected), actual);
            if(err !is null) {
                stderr.writefln("testStringObject failed: %s", err);
                assert(err is null);
            }

            break;
        default:
            break;
    }
}

/+++/
Program parse(string input) {
    auto lex = Lexer(input);
    auto parser = Parser(lex);

    return parser.parseProgram();
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
        VMTestCase!int("let one = 1; one", 1),
        VMTestCase!int("let one = 1; let two = 2; one + two", 3),
        VMTestCase!int("let one = 1; let two = one + one; one + two", 3),
    ];

    runVMTests!int(tests);
}

///
void testStringExpressions() {
    auto tests = [
        VMTestCase!string(`"monkey"`, "monkey"),
        VMTestCase!string(`"mon" + "key"`, "monkey"),
        VMTestCase!string(`"mon" + "key" + "banana"`, "monkeybanana"),
    ];

    runVMTests!string(tests);
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
    int[] a;
    auto tests = [
        VMTestCase!(int[])("[]", a),
        VMTestCase!(int[])("[1, 2, 3]", [1, 2, 3]),
        VMTestCase!(int[])("[1 + 2, 3 * 4, 5 + 6]", [3, 12, 11]),
    ];

    Objekt[] constants = [];        
    Objekt[] globals = new Objekt[GLOBALS_SIZE];
    auto symTable = new SymbolTable(null);

    foreach(tt; tests) {
        auto program = parse(tt.input);
        auto compiler = Compiler(symTable, constants);
        auto err = compiler.compile(program);
        if(err !is null) {
            stderr.writefln("compiler error: %s", err.msg);
            assert(err is null);
        }

        auto code = compiler.bytecode();
        auto vm = VM(code, globals);
        err = vm.run();
        if(err !is null) {
            stderr.writefln("vm error: %s", err.msg);
            assert(err is null);
        }

        auto stackElem = vm.lastPoppedStackElem();
        testArrayObject(tt.expected, stackElem);
    }
}

///
void testArrayObject(int[] expected, Objekt actual) {
    auto array = cast(Array) actual;
    if(array is null) {
        stderr.writefln("object not Array: %s (%s)", actual, actual);
        return;
    }

    if(array.elements.length != expected.length) {
        stderr.writefln("wrong num of elements. want=%d, got=%d",
                            expected.length, array.elements.length);
        return;
    }

    foreach(i, expectedElem; expected) {
        auto err = testIntegerObject(to!long(expectedElem), array.elements[i]);
        if(err !is null) {
            stderr.writefln("testIntegerObject failed: %s", err);
            assert(err is null);
        }
    }
}

///
void testHashLiterals() {
    size_t[HashKey] a;
    auto tests = [
        VMTestCase!(size_t[HashKey])("{}", a),
        VMTestCase!(size_t[HashKey]) ("{5: 2, 2: 3}", [
            (new Integer(5)).hashKey() : 2L,
            (new Integer(2)).hashKey() : 3L,
        ]),
        VMTestCase!(size_t[HashKey]) ("{1 + 1: 2 * 2, 3 + 3: 4 * 4}", [
            (new Integer(2)).hashKey() : 4L,
            (new Integer(6)).hashKey() : 16L,
        ])
    ];

    Objekt[] constants = [];        
    Objekt[] globals = new Objekt[GLOBALS_SIZE];
    auto symTable = new SymbolTable(null);

    foreach(tt; tests) {
        auto program = parse(tt.input);
        auto compiler = Compiler(symTable, constants);
        auto err = compiler.compile(program);
        if(err !is null) {
            stderr.writefln("compiler error: %s", err.msg);
            assert(err is null);
        }

        auto code = compiler.bytecode();
        auto vm = VM(code, globals);
        err = vm.run();
        if(err !is null) {
            stderr.writefln("vm error: %s", err.msg);
            assert(err is null);
        }

        auto stackElem = vm.lastPoppedStackElem();
        testHashObject(tt.expected, stackElem);
    }
}

///
void testHashObject(size_t[HashKey] expected, Objekt actual) {
    auto hash = cast(Hash) actual;
    if(hash is null) {
        stderr.writefln("object is not Hash. got=%s (%s)", actual, actual);
        assert(hash !is null);
    }

    if(hash.pairs.length != expected.length) {
        stderr.writefln("hash has wrong number of Pairs. want=%d, got=%d",
                            expected.length, hash.pairs.length);
        assert(hash.pairs.length == expected.length);
    }

    foreach(expectedKey, expectedValue; expected) {
        if(expectedKey !in hash.pairs) {
            stderr.writefln("no pair for given key in Pairs");
            assert(expectedKey in hash.pairs);
        }

        auto pair = hash.pairs[expectedKey];

        auto err = testIntegerObject(expectedValue, pair.value);
        if(err !is null) {
            stderr.writefln("testIntegerObject failed: %s", err);
            assert(err is null);
        }
    }
}

///
void testIntgerIndexExpressions() {
    auto tests = [
        VMTestCase!int("[1, 2, 3][1]", 2),
        VMTestCase!int("[1, 2, 3][0 + 2]", 3),
        VMTestCase!int("[[1, 1, 1]][0][0]", 1),
        VMTestCase!int("{5: 5, 2: 2}[5]", 5),
        VMTestCase!int("{5: 5, 2: 2}[2]", 2),
    ];

    runVMTests!int(tests);
}

///
void testNullIndexExpressions() {
    auto tests = [
        VMTestCase!Null("[][0]", NULL),
        VMTestCase!Null("[1, 2, 3][99]", NULL),
        VMTestCase!Null("[1][-1]", NULL),
    ];

    Objekt[] constants = [];        
    Objekt[] globals = new Objekt[GLOBALS_SIZE];
    auto symTable = new SymbolTable(null);

    foreach(tt; tests) {
        auto program = parse(tt.input);
        auto compiler = Compiler(symTable, constants);
        auto err = compiler.compile(program);
        if(err !is null) {
            stderr.writefln("compiler error: %s", err.msg);
            assert(err is null);
        }

        auto code = compiler.bytecode();
        auto vm = VM(code, globals);
        err = vm.run();
        if(err !is null) {
            stderr.writefln("vm error: %s", err.msg);
            assert(err is null);
        }

        auto stackElem = vm.lastPoppedStackElem();
        testNullObject(stackElem);
    }
}

///
void testCallingFunctionsWithoutArguments() {
    auto tests = [
        VMTestCase!int(`let fivePlusTen = fn() { 5 + 10; };fivePlusTen();`, 15),
        VMTestCase!int(`let one = fn() { 1; };let two = fn() { 2; };one() + two()`, 3),
        VMTestCase!int(`let a = fn() { 1 };let b = fn() { a() + 1 };let c = fn() { b() + 1 };c();`, 3),
    ];

    runVMTests!int(tests);
}

///
void testFunctionsWithReturnStatement() {
    auto tests = [
        VMTestCase!int(`let earlyExit = fn() { return 99; 100; };earlyExit();`, 99),
        VMTestCase!int(`let earlyExit = fn() { return 99; return 100; };earlyExit();`, 99),
    ];

    runVMTests!int(tests);
}

///
void testFunctionsWithoutReturnValue() {
    auto tests = [
        VMTestCase!Null(`let noReturn = fn() { };noReturn();`, NULL),
        VMTestCase!Null(`let noReturn = fn() { };let noReturnTwo = fn() { noReturn(); };noReturn();noReturnTwo();`, NULL),
    ];

    Objekt[] constants = [];        
    Objekt[] globals = new Objekt[GLOBALS_SIZE];
    auto symTable = new SymbolTable(null);

    foreach(tt; tests) {
        auto program = parse(tt.input);
        auto compiler = Compiler(symTable, constants);

        auto err = compiler.compile(program);
        if(err !is null) {
            stderr.writefln("compiler error: %s", err.msg);
            assert(err is null);
        }

        auto code = compiler.bytecode();
        auto vm = VM(code, globals);
        err = vm.run();
        if(err !is null) {
            stderr.writefln("vm error: %s", err.msg);
            assert(err is null);
        }

        auto stackElem = vm.lastPoppedStackElem();
        testNullObject(stackElem);
    }
}

///
void testCallingFunctionsWithBindings() {
    auto tests = [
        VMTestCase!int(
            `let one = fn() { let one = 1; one };one();`, 
            1
        ),
        VMTestCase!int(
            `
            let oneAndTwo = fn() { let one = 1; let two = 2; 
            one + two; };oneAndTwo();`, 
            3
        ),
        VMTestCase!int(
            `
            let oneAndTwo = fn() { let one = 1; let two = 2; one + two; };
            let threeAndFour = fn() { let three = 3; let four = 4; three + four; };
            oneAndTwo() + threeAndFour();
            `, 
            10
        ),
        VMTestCase!int(
            `
            let firstFoobar = fn() { let foobar = 50; foobar; };
            let secondFoobar = fn() { let foobar = 100; foobar; };
            firstFoobar() + secondFoobar();
            `,
            150
        ),
        VMTestCase!int(
            `
            let globalSeed = 50;
            let minusOne = fn() {
            let num = 1;
            globalSeed - num;
            }
            let minusTwo = fn() {
            let num = 2;
            globalSeed - num;
            }
            minusOne() + minusTwo();`,
            97
        ),
    ];

    runVMTests!int(tests);
}
///
void testFirstClassFunctions() {
    auto tests = [
        VMTestCase!int(
            `
            let returnsOneReturner = fn() {
            let returnsOne = fn() { 1; };
            returnsOne;
            };
            returnsOneReturner()();
            `,
            1
        )
    ];

    runVMTests!int(tests);
}

///
void testCallingFunctionsWithArgumentsAndBindings() {
    auto tests = [
        VMTestCase!int(
            `let identity = fn(a) { a; };identity(4);`,
            4
        ),
        VMTestCase!int(
            `let sum = fn(a, b) { a + b; };sum(1, 2);`,
            3
        ),
        VMTestCase!int(
            `let sum = fn(a, b) {let c = a + b;c;};sum(1, 2);`,
            3
        ),
        VMTestCase!int(
            `let sum = fn(a, b) {let c = a + b;c;};sum(1, 2) + sum(3, 4);`,
            10
        ),
        VMTestCase!int(
            `let sum = fn(a, b) {let c = a + b;c;};let outer = fn() {sum(1, 2) + sum(3, 4);};outer();`,
            10
        ),
        VMTestCase!int(
            `let globalNum = 10;let sum = fn(a, b) {let c = a + b;c + globalNum;};
            let outer = fn() {sum(1, 2) + sum(3, 4) + globalNum;};outer() + globalNum;`,
            50
        ),
    ];

    runVMTests!int(tests);
}

///
void testCallingFunctionsWithWrongArguments() {
    auto tests = [
        VMTestCase!string(
            `fn() { 1; }(1);`,
            `wrong number of arguments: want=0, got=1`,
        ),
        VMTestCase!string(
            `fn(a) { a; }();`,
            `wrong number of arguments: want=1, got=0`,
        ),
        VMTestCase!string(
            `fn(a, b) { a + b; }(1);`,
            `wrong number of arguments: want=2, got=1`,
        ),
    ];

    Objekt[] constants = [];        
    Objekt[] globals = new Objekt[GLOBALS_SIZE];
    auto symTable = new SymbolTable(null);

    foreach(tt; tests) {
        auto program = parse(tt.input);
        auto comp = Compiler(symTable, constants);

        auto err = comp.compile(program);
        if(err !is null) {
            stderr.writefln("compiler error: %s", err.msg);
            assert(err is null);
        }

        auto code = comp.bytecode();
        auto vm = VM(code, globals);
        err = vm.run();
        if (err is null) {
            stderr.writefln("expected VM error but resulted in none.");
            assert(err !is null);
        }

        if (err.msg != tt.expected) {
            stderr.writefln("wrong VM error: want=%q, got=%q", tt.expected, err);
            assert(err.msg == tt.expected);
        }
    }
}