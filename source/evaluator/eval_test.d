module evaluator.eval_test;

import std.stdio;
import std.typecons;

import lexer.lexer;
import parser.parser;
import objekt.objekt;
import evaluator.eval;


unittest {
    testEvalIntegerExpression();
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