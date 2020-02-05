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


unittest {
    testIntegerArithmetic();
    testBooleanExpressions();
    testIntegerConditional();
    testNullConditional();
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
    auto tests = [
        VMTestCase!Null("if (1 > 2) { 10 }", NULL),
        VMTestCase!Null("if (false) { 10 }", NULL),
    ];

    foreach(tt; tests) {
        auto program = parse(tt.input);
        auto compiler = Compiler();
        auto err = compiler.compile(program);
        if(err !is null) {
            stderr.writefln("compiler error: %s", err.msg);
            assert(err is null);
        }

        auto vm = VM(compiler.bytecode());
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
    foreach(tt; tests) {
        auto program = parse(tt.input);
        auto compiler = Compiler();
        auto err = compiler.compile(program);
        if(err !is null) {
            stderr.writefln("compiler error: %s", err.msg);
            assert(err is null);
        }

        auto vm = VM(compiler.bytecode());
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
            auto err = testBooleanObject(cast(bool) expected, actual);
            if(err !is null) {
                stderr.writefln("testBooleanObject failed: %s", err.msg);
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