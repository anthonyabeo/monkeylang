module vm.vm_test;

import std.stdio;
import std.string;
import std.conv;

import vm.vm;
import ast.ast;
import code.code;
import lexer.lexer;
import objekt.objekt;
import parser.parser;
import compiler.compiler;


unittest {
    testIntegerArithmetic();
}

///
void testIntegerArithmetic() {
    auto tests = [
        VMTestCase!int("1", 1),
        VMTestCase!int("2", 2),
        VMTestCase!int("1+2", 3),
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
    foreach(tt; tests) {
        auto program = parse(tt.input);
        auto compiler = Compiler();
        auto err = compiler.compile(program);
        if(err !is null) {
            stderr.writefln("compiler error: %s", err);
            assert(err is null);
        }

        auto vm = VM(compiler.bytecode());
        err = vm.run();
        if(err !is null) {
            stderr.writefln("vm error: %s", err);
            assert(err is null);
        }

        auto stackElem = vm.stackTop();
        testExpectedObject!T(tt.expected, stackElem);
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