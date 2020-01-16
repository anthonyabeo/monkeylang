module ast.ast_test;

import std.stdio;

import ast.ast;
import token.token;

unittest {
    auto program = new Program();

    auto let = new LetStatement(Token(TokenType.LET, "let"));
    let.name = new Identifier(Token(TokenType.IDENTIFIER, "myVar"), "myVar");
    let.value = new Identifier(Token(TokenType.IDENTIFIER, "anotherVar"), "anotherVar");

    program.statements = [let];

    assert(program.asString == "let myVar = anotherVar;");
}