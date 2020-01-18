module parser.parser_test;

import std.stdio : stderr, writeln, writefln;
import std.typecons : tuple, Tuple;
import std.string : format;

import parser.parser;
import lexer.lexer;
import ast.ast;

unittest {
    auto input = "let x = 5;
                  let y = 10;
                  let foobar = 838383;";
    
    void checkParserErrors(ref Parser p) {
        auto errors = p.errors();
        if(errors.length == 0)
            return;

        stderr.writefln("parser produced %d errors", errors.length);
        foreach(err; errors) 
            stderr.writefln("parser error: %s", err);

        assert(false);
    }

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

    bool testIntegerLiteral(Expression il, long value) {
        auto integ = cast(IntegerLiteral) il;

        if(integ is null) return false;
        if(integ.value != value) return false;
        if(integ.tokenLiteral() != format("%d", value)) return false;

        return true;
    }

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
        MoreInfixEntry("3 + 4 * 5 == 3 * 1 + 4 * 5", "((3 + (4 * 5)) == ((3 * 1) + (4 * 5)))")
    ];

    foreach(t; moreTests) {
        auto lex3 = Lexer(t.input);
        auto parser3 = Parser(lex3);
        auto program3 = parser3.parseProgram();
        checkParserErrors(parser3);

        assert(program3.asString() == t.expected);
    }
}