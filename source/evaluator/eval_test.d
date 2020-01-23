module evaluator.eval_test;

import std.stdio;
import std.typecons;

import lexer.lexer;
import parser.parser;
import objekt.objekt;
import evaluator.eval;


unittest {
    testEvalIntegerExpression();
    testEvalBooleanExpression();
}

///
void testEvalIntegerExpression() {
    alias IntExp = Tuple!(string, "input", long, "expected");
    auto tests = [
        IntExp("5", 5),
        IntExp("10", 10)
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
        BoolExp("false", false)
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