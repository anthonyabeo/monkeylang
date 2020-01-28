module evaluator.eval_test;

import std.stdio;
import std.typecons;
import std.conv;

import lexer.lexer;
import parser.parser;
import objekt.objekt;
import evaluator.eval;
import objekt.environment;
import evaluator.builtins : NULL, TRUE, FALSE;

unittest {
    testEvalIntegerExpression();
    testEvalBooleanExpression();
    testBangOperator();
    testIfElseExpressions();
    testReturnStatements();
    testErrorHandling(); 
    testLetStatements();
    testFunctionObject();
    testClosures();
    testStringLiteral();
    testStringConcatenation();
    testBuiltInFunctions();
    testArrayLiterals();
    testArrayIndexExpression();
    testHashLiterals();
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
    auto env = new Environment();

    return eval(program, env);
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

/+++/
void testIfElseExpressions() {
    alias IfElseExp = Tuple!(string, "input", string, "expected");

    auto tests = tuple(
        IfElseExp("if (true) { 10 }", "10"),
        IfElseExp("if (false) { 10 }", "null"),
        IfElseExp("if (1) { 10 }", "10"),
        IfElseExp("if (1 < 2) { 10 }", "10"),
        IfElseExp("if (1 > 2) { 10 }", "null"),
        IfElseExp("if (1 > 2) { 10 } else { 20 }", "20"),
        IfElseExp("if (1 < 2) { 10 } else { 20 }", "10")
    );

    foreach(tt; tests) {
        auto evaluated = testEval(tt.input);

        try {
            auto integer = parse!int(tt.expected);
            assert(testIntegerObject(evaluated, integer)); 
        }
        catch(ConvException ce) {
            assert(testNullObject(evaluated));
        }       
    }
}

/+++/
bool testNullObject(Objekt obj) {
    if(obj.inspect() != NULL.inspect()) {
        stderr.writeln("object is not NULL. got=%s (%s)", obj, obj);
        return false;
    }

    return true;
}

/+++/
void testReturnStatements() {
    alias RetS = Tuple!(string, "input", long, "expected");

    auto tests = [
        RetS("return 10;", 10),
        RetS("return 10; 9;", 10),
        RetS("return 2 * 5; 9;", 10),
        RetS("9; return 2 * 5; 9;", 10)
    ];

    foreach(tt; tests) {
        auto evaluated = testEval(tt.input);
        assert(testIntegerObject(evaluated, tt.expected));
    }
}

///
void testErrorHandling() {
    alias ErrS = Tuple!(string, "input", string, "expectedMessage");

    auto tests = [
        ErrS("5 + true;", "type mismatch: INTEGER + BOOLEAN"),
        ErrS("5 + true; 5;", "type mismatch: INTEGER + BOOLEAN"),
        ErrS("-true", "unknown operator: -BOOLEAN"),
        ErrS("true + false;", "unknown operator: BOOLEAN + BOOLEAN"),
        ErrS("5; true + false; 5", "unknown operator: BOOLEAN + BOOLEAN"),
        ErrS("if (10 > 1) { true + false; }", "unknown operator: BOOLEAN + BOOLEAN"),
        ErrS("
                if (10 > 1) {
                    if (10 > 1) {
                        return true + false;
                    }
                    return 1;
                }
            ", 
            "unknown operator: BOOLEAN + BOOLEAN"
        ),
        ErrS("foobar", "identifier not found: foobar"),
        ErrS(`"Hello" - "World"`, "unknown operator: STRING - STRING"),
    ];

    foreach(tt; tests) {
        auto evaluated = testEval(tt.input);

        auto errObj = cast(Err) evaluated;
        if(errObj is null) {
            stderr.writeln("no error object returned. got=%s(%s)", evaluated, evaluated);
            continue;
        }

        assert(errObj.message == tt.expectedMessage);
    }
}

/+++/
void testLetStatements() {
    alias LetS = Tuple!(string, "input", long, "expected");
    auto tests = [
        LetS("let a = 5; a;", 5),
        LetS("let a = 5 * 5; a;", 25),
        LetS("let a = 5; let b = a; b;", 5),
        LetS("let a = 5; let b = a; let c = a + b + 5; c;", 15)
    ];

    foreach(tt; tests) {
        assert(testIntegerObject(testEval(tt.input), tt.expected));
    }
}

void testFunctionObject() {
    auto input = "fn(x) { x + 2; };";

    auto evaluated = testEval(input);

    auto fn = cast(Function) evaluated;
    if(fn is null) {
        stderr.writeln("object is not Function. got=%s (%s)", evaluated, evaluated);
        assert(fn !is null);
    }

    if(fn.parameters.length != 1) {
        stderr.writefln("function has wrong parameters. Parameters=%s", fn.parameters);
        assert(fn.parameters.length == 1);
    }

    if(fn.parameters[0].asString() != "x") {
        stderr.writeln("parameter is not 'x'. got=%s", fn.parameters[0]);
        assert(fn.parameters[0].asString() == "x");
    }

    auto expectedBody = "(x + 2)";

    if(fn.fnBody.asString() != expectedBody) {
        stderr.writeln("body is not %s. got=%s", expectedBody, fn.fnBody.asString());
        assert(fn.fnBody.asString() == expectedBody);
    }
}

void testFunctionApplication() {
    alias FnApp = Tuple!(string, "input", long, "expected");

    auto tests = [
        FnApp("let identity = fn(x) { x; }; identity(5);", 5),
        FnApp("let identity = fn(x) { return x; }; identity(5);", 5),
        FnApp("let double = fn(x) { x * 2; }; double(5);", 10),
        FnApp("let add = fn(x, y) { x + y; }; add(5, 5);", 10),
        FnApp("let add = fn(x, y) { x + y; }; add(5 + 5, add(5, 5));", 20),
        FnApp("fn(x) { x; }(5)", 5)
    ];

    foreach(tt; tests) {
        assert(testIntegerObject(testEval(tt.input), tt.expected));
    }
}

void testClosures() {
    auto input = "
        let newAdder = fn(x) {
            fn(y) { x + y };
        };

        let addTwo = newAdder(2);
        addTwo(2);
    ";

    testIntegerObject(testEval(input), 4);
}

void testStringLiteral() {
    auto input = `"hello world"`;

    auto evaluated = testEval(input);
    auto str = cast(String) evaluated;
    if(str is null) {
        stderr.writeln("object is not String. got=%s (%s)", evaluated, evaluated);
        assert(str !is null);
    }

    if(str.value != "hello world") {
        stderr.writeln("String has wrong value. got=%s", str.value);
        assert(str.value == "hello world");
    }
}

void testStringConcatenation() {
    auto input = `"Hello" + " " + "World!"`;

    auto evaluated = testEval(input);
    auto str = cast(String) evaluated;
    if(str is null) {
        stderr.writeln("object is not String. got=%s (%s)", evaluated, evaluated);
        assert(str !is null);
    }

    if(str.value != "Hello World!") {
        stderr.writeln("String has wrong value. got=%s", str.value);
        assert(str.value == "Hello World!");
    }
}

void testBuiltInFunctions() {
    struct BinFxn(T) {
        string input;
        T expected;
    }

    auto tests = tuple(
        BinFxn!int(`len("")`, 0),
        BinFxn!int(`len("four")`, 4),
        BinFxn!int(`len("hello world")`, 11),
        BinFxn!string(`len(1)`, "argument to `len` not supported, got INTEGER"),
        BinFxn!string(`len("one", "two")`, "wrong number of arguments. got=2, want=1")
    );

    foreach(tt; tests) {
        auto evaluated = testEval(tt.input);
        switch(to!string(typeid(typeof(tt.expected)))) {
            case "int":
                assert(testIntegerObject(evaluated, to!long(tt.expected)));
                break;
            case "immutable(char)[]":
                auto errObj = cast(Err) evaluated;
                if(errObj is null) {
                    stderr.writeln("object is not Error. got=%s (%s)", evaluated, evaluated);
                    continue;
                }

                if(errObj.message != to!string(tt.expected)) {
                    stderr.writeln("wrong error message. expected=%s, got=%s", tt.expected, errObj.message);
                    assert(errObj.message == to!string(tt.expected));
                }
                break;
            default:
                continue;
        }
    }
}

void testArrayLiterals() {
    auto input = "[1, 2 * 2, 3 + 3]";

    auto evaluated = testEval(input);
    auto result = cast(Array) evaluated;
    if(result is null) {
        stderr.writeln("object is not Array. got=%s (%s)", evaluated.inspect(), evaluated.inspect());
        assert(result !is null);
    }

    if(result.elements.length != 3) {
        stderr.writeln("array has wrong num of elements. got=%d", result.elements.length);
        assert(result.elements.length == 3);
    }

    testIntegerObject(result.elements[0], 1);
    testIntegerObject(result.elements[1], 4);
    testIntegerObject(result.elements[2], 6);
}

void testArrayIndexExpression() {
    struct ArrIndExp(T) {
        string input;
        T expected;
    }

    auto tests = tuple(
        ArrIndExp!int("[1, 2, 3][0]", 1),
        ArrIndExp!int("[1, 2, 3][1]", 2),
        ArrIndExp!int("[1, 2, 3][2]",3),
        ArrIndExp!int("let i = 0; [1][i];", 1),
        ArrIndExp!int("[1, 2, 3][1 + 1];", 3),
        ArrIndExp!int("let myArray = [1, 2, 3]; myArray[2];", 3),
        ArrIndExp!int("let myArray = [1, 2, 3]; myArray[0] + myArray[1] + myArray[2];", 6),
        ArrIndExp!int("let myArray = [1, 2, 3]; let i = myArray[0]; myArray[i]", 2),
        ArrIndExp!string("[1, 2, 3][3]", "null"),
        ArrIndExp!string("[1, 2, 3][-1]", "null")
    );

    foreach(tt; tests) {
        auto evaluated = testEval(tt.input);
        try {
            auto integer = to!long(tt.expected);
            assert(testIntegerObject(evaluated, integer));
        }
        catch(ConvException ce) {
            assert(testNullObject(evaluated));
        }   
    }
}

void testHashLiterals() {
    auto input =`let two = "two";
                {
                    "five": 10 - 9,
                    two: 1 + 1,
                    "thr" + "ee": 6 / 2,
                    4: 4,
                    true: 5,
                    false: 6
                }`;

    auto evaluated = testEval(input);
    auto result = cast(Hash) evaluated;
    if(result is null) {
        stderr.writeln("Eval didn't return Hash. got=%s (%s)", evaluated, evaluated);
        assert(result !is null);
    }

    auto expected = [
        (new String("five")).hashKey()   : 1,
        (new String("two")).hashKey()   : 2,
        (new String("three")).hashKey() : 3,
        (new Integer(4)).hashKey()      : 4,
        TRUE.hashKey()                  : 5,
        FALSE.hashKey()                 : 6,
    ];

    if(result.pairs.length != expected.length) {
        stderr.writefln("Hash has wrong num of pairs. got=%d", result.pairs.length);
        assert(result.pairs.length == expected.length);
    }

    foreach(expKey, expVal; expected) {
        auto pair = result.pairs[expKey];
        assert(testIntegerObject(pair.value, expVal));
    }
}