module evaluator.eval_test;

import std.stdio;
import std.typecons;
import std.conv;

import lexer.lexer;
import parser.parser;
import objekt.objekt;
import evaluator.eval;


unittest {
    testEvalIntegerExpression();
    testEvalBooleanExpression();
    testBangOperator();
    testIfElseExpressions();
}

///
void testEvalIntegerExpression() {
    alias IntExp = Tuple!(string, "input", long, "expected");
    auto tests = [
        IntExp("5", 5),
        IntExp("10", 10),
        IntExp("-5", -5),
        IntExp("-10", -10),
        IntExp("5 + 5 + 5 + 5 - 10", 10),
        IntExp("2 * 2 * 2 * 2 * 2", 32),
        IntExp("-50 + 100 + -50", 0),
        IntExp("5 * 2 + 10", 20),
        IntExp("5 + 2 * 10", 25),
        IntExp("20 + 2 * -10", 0),
        IntExp("50 / 2 * 2 + 10", 60),
        IntExp("2 * (5 + 10)", 30),
        IntExp("3 * 3 * 3 + 10", 37),
        IntExp("3 * (3 * 3) + 10", 37),
        IntExp("(5 + 10 * 2 + 15 / 3) * 2 + -10", 50)
    ];

    foreach(tt; tests) {
        auto evaluated = testEval(tt.input);
        assert(testIntegerObject(evaluated, tt.expected));
    }
}

///
void testEvalBooleanExpression() {
    alias BoolExp = Tuple!(string, "input", bool, "expected");
    auto tests = [
        BoolExp("true", true),
        BoolExp("false", false),
        BoolExp("1 < 2", true),
        BoolExp("1 > 2", false),
        BoolExp("1 < 1", false),
        BoolExp("1 > 1", false),
        BoolExp("1 == 1", true),
        BoolExp("1 != 1", false),
        BoolExp("1 == 2", false),
        BoolExp("1 != 2", true),
        BoolExp("true == true", true),
        BoolExp("false == false", true),
        BoolExp("true == false", false),
        BoolExp("true != false", true),
        BoolExp("false != true", true),
        BoolExp("(1 < 2) == true", true),
        BoolExp("(1 < 2) == false", false),
        BoolExp("(1 > 2) == true", false),
        BoolExp("(1 > 2) == false", true)
    ];

    foreach(tt; tests) {
        auto evaluated = testEval(tt.input);
        assert(testBooleanObject(evaluated, tt.expected));
    }
}

///
Objekt testEval(string input) {
    auto lex = Lexer(input);
    auto parser = Parser(lex);
    auto program = parser.parseProgram();

    return eval(program);
}

///
bool testIntegerObject(Objekt obj, long expected) {
    auto intObj = cast(Integer) obj;
    if(intObj is null) {
        stderr.writefln("object is not Integer. got=%s (%s)", obj, obj);
        return false;
    }

    if(intObj.value != expected) {
        stderr.writefln("object has wrong value. got=%d, want=%d", 
                         intObj.value, expected);
        return false;
    }

    return true;
}

///
bool testBooleanObject(Objekt obj, bool expected) {
    auto boolObj = cast(Boolean) obj;
    if(boolObj is null) {
        stderr.writefln("object is not Boolean. got=%s (%s)", obj, obj);
        return false;
    }

    if(boolObj.value != expected) {
        stderr.writefln("object has wrong value. got=%d, want=%d", 
                         boolObj.value, expected);
        return false;
    }

    return true;
}

///
void testBangOperator() {
    alias BangExp = Tuple!(string, "input", bool, "expected");

    auto tests = [
        BangExp("!true", false),
        BangExp("!false", true),
        BangExp("!5", false),
        BangExp("!!true", true),
        BangExp("!!false", false),
        BangExp("!!5", true)
    ];

    foreach (tt; tests) {
        auto evaluated = testEval(tt.input);
        assert(testBooleanObject(evaluated, tt.expected));
    }
}

void testIfElseExpressions() {
    ///
    struct IfElseExp (T) {
        string input;        /// input
        T expected;          /// expected
    }

    auto tests = tuple(
        IfElseExp!string("if (true) { 10 }", "10"),
        // IfElseExp!string("if (false) { 10 }", "null"),
        // IfElseExp!string("if (1) { 10 }", "10"),
        // IfElseExp!string("if (1 < 2) { 10 }", "10"),
        // IfElseExp!string("if (1 > 2) { 10 }", "null"),
        // IfElseExp!string("if (1 > 2) { 10 } else { 20 }", "20"),
        // IfElseExp!string("if (1 < 2) { 10 } else { 20 }", "10")
    );

    foreach(tt; tests) {
        auto evaluated = testEval(tt.input);

        try {
            // writeln(evaluated.inspect());
            auto integer = parse!int(tt.expected);
            assert(testIntegerObject(evaluated, integer)); 
        }
        catch(ConvException ce) {
            assert(testNullObject(evaluated));
        }
            
    }
}

bool testNullObject(Objekt obj) {
    if(obj.inspect() == NULL.inspect()) {
        stderr.writeln("object is not NULL. got=%s (%s)", obj, obj);
        return false;
    }

    return true;
}