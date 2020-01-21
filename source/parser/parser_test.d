module parser.parser_test;

import std.stdio : stderr, writeln, writefln;
import std.typecons : tuple, Tuple;
import std.string : format;
import std.conv : parse, to;

import parser.parser;
import lexer.lexer;
import ast.ast;

unittest {
    auto input = "let x = 5;
                  let y = 10;
                  let foobar = 838383;";

    auto lex = Lexer(input);
    auto parser = Parser(lex);
    auto program = parser.parseProgram();
    checkParserErrors(parser);

    assert(program !is null);
    assert(program.statements.length == 3);

    auto tests = [
        tuple("x"),
        tuple("y"),
        tuple("foobar")
    ];

    foreach(offset, tt; tests) {
        auto stmt = program.statements[offset];
        assert(testLetStatement(stmt, tt[0]));
    }

    input = "return 5;
             return 10;
             return 993322;";

    lex = Lexer(input);
    parser = Parser(lex);
    program = parser.parseProgram();
    checkParserErrors(parser);

    assert(program !is null);
    assert(program.statements.length == 3);

    foreach(stmt; program.statements) {
        auto returnStmt = cast(ReturnStatement) stmt;
        assert(returnStmt !is null);
        assert(returnStmt.tokenLiteral() == "return");
    }

    input = "foobar;";

    lex = Lexer(input);
    parser = Parser(lex);
    program = parser.parseProgram();
    checkParserErrors(parser);

    assert(program !is null);
    assert(program.statements.length == 1);

    auto expStmt = cast(ExpressionStatement) program.statements[0]; 
    assert(expStmt !is null);

    auto ident = cast(Identifier) expStmt.expression;
    assert(ident !is null);
    assert(ident.value == "foobar");
    assert(ident.tokenLiteral() == "foobar");

    // testing integer literals
    input = "5;";

    lex = Lexer(input);
    parser = Parser(lex);
    program = parser.parseProgram();
    checkParserErrors(parser);

    assert(program !is null);
    assert(program.statements.length == 1);

    expStmt = cast(ExpressionStatement) program.statements[0]; 
    assert(expStmt !is null);

    auto iliteral = cast(IntegerLiteral) expStmt.expression;
    assert(iliteral !is null);
    assert(iliteral.value == 5);
    assert(iliteral.tokenLiteral() == "5");

    // testing prefix literals
    alias Entry = Tuple!(string, "input", 
                         string, "operator", 
                         long, "integerValue");

    auto prefixTests = [
        Entry("!5;", "!", 5),
        Entry("-15;", "-", 15)
    ];

    foreach(t; prefixTests) {
        auto lex1 = Lexer(t.input);
        auto parser1 = Parser(lex1);
        auto program1 = parser1.parseProgram();
        checkParserErrors(parser1);

        assert(program1 !is null);
        assert(program1.statements.length == 1);

        auto expStmt1 = cast(ExpressionStatement) program1.statements[0]; 
        assert(expStmt1 !is null);

        auto prefixExpr = cast(PrefixExpression) expStmt1.expression;
        assert(prefixExpr.operator == t.operator);

        if(!testIntegerLiteral(prefixExpr.right, t.integerValue)) return;
    }

    // TESTING INFIX OPERATORS
    alias InfixEntry = Tuple!(string, "input", long, "leftValue", 
                              string, "operator", long, "rightValue");

    auto infixTests = [
        InfixEntry("5 + 5;", 5, "+", 5),
        InfixEntry("5 - 5;", 5, "-", 5),
        InfixEntry("5 * 5;", 5, "*", 5),
        InfixEntry("5 / 5;", 5, "/", 5),
        InfixEntry("5 > 5;", 5, ">", 5),
        InfixEntry("5 < 5;", 5, "<", 5),
        InfixEntry("5 == 5;", 5, "==", 5),
        InfixEntry("5 != 5;", 5, "!=", 5),
    ];

    foreach(t; infixTests) {
        auto lex2 = Lexer(t.input);
        auto parser2 = Parser(lex2);
        auto program2 = parser2.parseProgram();
        checkParserErrors(parser2);

        assert(program2 !is null);
        assert(program2.statements.length == 1);

        auto expStmt2 = cast(ExpressionStatement) program2.statements[0]; 
        assert(expStmt2 !is null);

        auto infixExpr = cast(InfixExpression) expStmt2.expression;

        if(!testIntegerLiteral(infixExpr.left, t.leftValue)) return;
        assert(infixExpr.operator == t.operator);
        if(!testIntegerLiteral(infixExpr.right, t.rightValue)) return;
    }
    

    alias MoreInfixEntry = Tuple!(string, "input", string, "expected");
    auto moreTests = [
        MoreInfixEntry("-a * b", "((-a) * b)"),
        MoreInfixEntry("!-a", "(!(-a))"),
        MoreInfixEntry("a + b + c", "((a + b) + c)"),
        MoreInfixEntry("a + b - c", "((a + b) - c)"),
        MoreInfixEntry("a * b * c", "((a * b) * c)"),
        MoreInfixEntry("a * b / c", "((a * b) / c)"),
        MoreInfixEntry("a + b / c", "(a + (b / c))"),
        MoreInfixEntry("a + b * c + d / e - f", "(((a + (b * c)) + (d / e)) - f)"),
        MoreInfixEntry("3 + 4; -5 * 5", "(3 + 4)((-5) * 5)"),
        MoreInfixEntry("5 > 4 == 3 < 4", "((5 > 4) == (3 < 4))"),
        MoreInfixEntry("5 < 4 != 3 > 4", "((5 < 4) != (3 > 4))"),
        MoreInfixEntry("3 + 4 * 5 == 3 * 1 + 4 * 5", "((3 + (4 * 5)) == ((3 * 1) + (4 * 5)))"),
        MoreInfixEntry("true", "true"),
        MoreInfixEntry("false", "false"),
        MoreInfixEntry("3 > 5 == false", "((3 > 5) == false)"),
        MoreInfixEntry("3 < 5 == true", "((3 < 5) == true)"),
        MoreInfixEntry("(5 + 5) * 2", "((5 + 5) * 2)"),
        MoreInfixEntry("2 / (5 + 5)", "(2 / (5 + 5))"),
        MoreInfixEntry("-(5 + 5)", "(-(5 + 5))"),
        MoreInfixEntry("!(true == true)", "(!(true == true))"),
        MoreInfixEntry("a + add(b * c) + d", "((a + add((b * c))) + d)"),
        MoreInfixEntry("add(a, b, 1, 2 * 3, 4 + 5, add(6, 7 * 8))", "add(a, b, 1, (2 * 3), (4 + 5), add(6, (7 * 8)))"),
        MoreInfixEntry("add(a + b + c * d / f + g)", "add((((a + b) + ((c * d) / f)) + g))")
    ];

    foreach(t; moreTests) {
        auto lex3 = Lexer(t.input);
        auto parser3 = Parser(lex3);
        auto program3 = parser3.parseProgram();
        checkParserErrors(parser3);

        assert(program3.asString() == t.expected);
    }

    // TEST IF STATEMENT
    input = "if (x < y) { x }" ;

    auto lex4 = Lexer(input);
    auto parser4 = Parser(lex4);
    auto program4 = parser4.parseProgram();
    checkParserErrors(parser4);

    assert(program4 !is null);
    assert(program4.statements.length == 1);

    auto expStmt4 = cast(ExpressionStatement) program4.statements[0]; 
    assert(expStmt4 !is null);

    auto ifExpr = cast(IfExpression) expStmt4.expression;
    assert(ifExpr !is null);

    assert(testInfixExpression(ifExpr.condition, "x", "<", "y"));

    assert(ifExpr.consequence.statements.length == 1);

    auto conseq = cast(ExpressionStatement) ifExpr.consequence.statements[0];
    assert(conseq !is null);

    assert(testIdentifier(conseq.expression, "x"));
    assert(ifExpr.alternative is null);

    testFunctionLiteralParsing();
    testCallExpressionParsing();
}

/+++/
void checkParserErrors(ref Parser p) {
    auto errors = p.errors();
    if(errors.length == 0)
        return;

    stderr.writefln("parser produced %d errors", errors.length);
    foreach(err; errors) 
        stderr.writefln("parser error: %s", err);

    assert(false);
}

/+++/
bool testLetStatement(Statement stmt, string name) {
    if(stmt.tokenLiteral() != "let") {
        stderr.writefln("stmt.tokenLiteral not 'let'. got=%s", stmt.tokenLiteral());
        return false;
    }

    auto letStmt = cast(LetStatement) stmt;
    if(letStmt is null) {
        stderr.writefln("stmt is not a LetStatement. It is a %s", stmt);
        return false;
    }

    if(letStmt.name.tokenLiteral() != name) {
        stderr.writefln("letStmt.name.tokenLiteral is not '%s'. But rather %s", 
                        name, letStmt.name.tokenLiteral());
        return false;
    }

    return true;
}

/+++/
bool testInfixExpression(T, E)(Expression expr, T left, string operator, E right) {
    auto opExp = cast(InfixExpression) expr;
    if(opExp is null) {
        stderr.writefln("exp is not ast.InfixExpression. got=%s(%s)", expr, expr);
        return false;
    }

    if(!testLiteralExpression(opExp.left, left))
        return false;

    if(opExp.operator != operator) {
        stderr.writefln("exp.Operator is not '%s'. got=%s", opExp.operator, operator);
        return false;
    }

    if(!testLiteralExpression(opExp.right, right))
        return false;

    return true;
}

/+++/
bool testLiteralExpression(T) (Expression expr, T expected) {
    switch(to!string(typeid(expected))) {
        case "int":
            return testIntegerLiteral(expr, to!long(expected));
        case "long":
            return testIntegerLiteral(expr, to!long(expected));
        case "immutable(char)[]":
            return testIdentifier(expr, to!string(expected));
        default:
            stderr.writefln("type of exp not handled. got=%s", expr.asString());
            return false;
    }
}

/+++/
bool testIdentifier(Expression expr, string value) {
    auto ident = cast(Identifier) expr;
    if(ident is null) {
        stderr.writefln("exp not *ast.Identifier. got=%s", expr.asString());
        return false;
    }

    if(ident.value != value) {
        stderr.writefln("ident.Value not %s. got=%s", value, ident.value);
        return false;
    }

    if(ident.tokenLiteral() != value) {
        stderr.writefln("ident.TokenLiteral not %s. got=%s", value, ident.tokenLiteral());
        return false;
    }

    return true;
}

/+++/
bool testIntegerLiteral(Expression il, long value) {
    auto integ = cast(IntegerLiteral) il;

    if(integ is null) return false;
    if(integ.value != value) return false;
    if(integ.tokenLiteral() != format("%d", value)) return false;

    return true;
}

/+++/
void testFunctionLiteralParsing() {
    string input = "fn(x, y) { x + y; }";

    auto lexer = Lexer(input);
    auto parser = Parser(lexer);
    auto program = parser.parseProgram();
    checkParserErrors(parser);

    assert(program !is null);
    assert(program.statements.length == 1);

    auto stmt = cast(ExpressionStatement) program.statements[0];
    assert(stmt !is null);

    auto fxn = cast(FunctionLiteral) stmt.expression;
    assert(fxn !is null);
    assert(fxn.parameters.length == 2);

    testLiteralExpression(fxn.parameters[0], "x");
    testLiteralExpression(fxn.parameters[1], "y");

    assert(fxn.fnBody.statements.length == 1);

    auto bodyStmt = cast(ExpressionStatement) fxn.fnBody.statements[0];
    assert(bodyStmt !is null);

    testInfixExpression(bodyStmt.expression, "x", "+", "y");
}

/+++/
void testFunctionParameterParsing() {
    alias FnStruct = Tuple!(string, "input", string[], "expectedParams");

    auto tests = [
        FnStruct("fn() {};", []),
        FnStruct("fn(x) {};", ["x"]),
        FnStruct("fn(x, y, z) {};", ["x", "y", "z"])
    ];

    foreach(tt; tests) {
        auto lexer = Lexer(tt.input);
        auto parser = Parser(lexer);
        auto program = parser.parseProgram();
        checkParserErrors(parser);

        auto stmt = cast(ExpressionStatement) program.statements[0];
        assert(stmt !is null);

        auto fxn = cast(FunctionLiteral) stmt.expression;

        assert(fxn.parameters.length == tt.expectedParams.length);

        foreach(i, ident; tt.expectedParams) {
            testLiteralExpression(fxn.parameters[i], ident);
        }
    }
}

/+++/
void testCallExpressionParsing() {
    string input = "add(1, 2 * 3, 4 + 5);";
    
    auto lexer = Lexer(input);
    auto parser = Parser(lexer);
    auto program = parser.parseProgram();
    checkParserErrors(parser);

    assert(program !is null);
    assert(program.statements.length == 1);

    auto stmt = cast(ExpressionStatement) program.statements[0];
    assert(stmt !is null);

    auto callExpr = cast(CallExpression) stmt.expression;
    assert(callExpr !is null);

    if(!testIdentifier(callExpr.fxn, "add"))
        return;

    assert(callExpr.args.length == 3);

    testLiteralExpression(callExpr.args[0], 1);
    testInfixExpression(callExpr.args[1], 2L, "*", 3L);
    testInfixExpression(callExpr.args[2], 4L, "+", 5L);
}

///
struct LetS (T) {
    string input;                   /// input
    string expectedIdentifier;      ///input
    T expectedValue;                /// input
}

///
void testLetStatements() {
    auto tests = tuple(
        LetS!int("let x = 5;", "x", 5),
        LetS!bool("let y = true;", "y", true),
        LetS!string("let foobar = y;", "foobar", "y")
    );

    foreach (tt; tests) {
        auto lexer = Lexer(tt.input);
        auto parser = Parser(lexer);
        auto program = parser.parseProgram();
        checkParserErrors(parser);

        assert(program !is null);
        assert(program.statements.length == 1);

        auto stmt = program.statements[0];
        if(!testLetStatement(stmt, tt.expectedIdentifier))
            return;

        auto val = (cast(LetStatement) stmt).value;

        if(!testLiteralExpression(val, tt.expectedValue))
            return;
    }
}