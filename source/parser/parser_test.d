module parser.parser_test;

import std.stdio : stderr, writeln;
import std.typecons : tuple;

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
}