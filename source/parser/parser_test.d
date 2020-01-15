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
    
    auto lex = Lexer(input);
    auto parser = Parser(lex);
    auto program = parser.parseProgram();

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

}