module lexer.lexer_test;

import std.stdio;

import token.token;
import lexer.lexer;

unittest {
    string input = "=+(){},;";
    Token[] tests  = [
        Token(TokenType.ASSIGN, "="),
        Token(TokenType.PLUS, "+"),
        Token(TokenType.LPAREN, "("),
        Token(TokenType.RPAREN, ")"),
        Token(TokenType.LBRACE, "{"),
        Token(TokenType.RBRACE, "}"),
        Token(TokenType.COMMA, ","),
        Token(TokenType.SEMICOLON, ";"),
        Token(TokenType.EOF, "")
    ];

    auto lexer = new Lexer(input);
    foreach(index, token; tests) {
        auto tok = lexer.nextToken();
        
        assert(tok.type == token.type);
        assert(tok.literal == token.literal);
    }

    input = "let five = 5;
             let ten = 10;

             let add = fn(x, y) {
                x + y;
             };
             let result = add(five, ten);";
    
    tests = [
        Token(TokenType.LET, "let"),
        Token(TokenType.IDENTIFIER, "five"),
        Token(TokenType.ASSIGN, "="),
        Token(TokenType.INT, "5"),
        Token(TokenType.SEMICOLON, ";"),
        Token(TokenType.LET, "let"),
        Token(TokenType.IDENTIFIER, "ten"),
        Token(TokenType.ASSIGN, "="),
        Token(TokenType.INT, "10"),
        Token(TokenType.SEMICOLON, ";"),
        Token(TokenType.LET, "let"),
        Token(TokenType.IDENTIFIER, "add"),
        Token(TokenType.ASSIGN, "="),
        Token(TokenType.FUNCTION, "fn"),
        Token(TokenType.LPAREN, "("),
        Token(TokenType.IDENTIFIER, "x"),
        Token(TokenType.COMMA, ","),
        Token(TokenType.IDENTIFIER, "y"),
        Token(TokenType.RPAREN, ")"),
        Token(TokenType.LBRACE, "{"),
        Token(TokenType.IDENTIFIER, "x"),
        Token(TokenType.PLUS, "+"),
        Token(TokenType.IDENTIFIER, "y"),
        Token(TokenType.SEMICOLON, ";"),
        Token(TokenType.RBRACE, "}"),
        Token(TokenType.SEMICOLON, ";"),
        Token(TokenType.LET, "let"),
        Token(TokenType.IDENTIFIER, "result"),
        Token(TokenType.ASSIGN, "="),
        Token(TokenType.IDENTIFIER, "add"),
        Token(TokenType.LPAREN, "("),
        Token(TokenType.IDENTIFIER, "five"),
        Token(TokenType.COMMA, ","),
        Token(TokenType.IDENTIFIER, "ten"),
        Token(TokenType.RPAREN, ")"),
        Token(TokenType.SEMICOLON, ";"),
        Token(TokenType.EOF, ""),
    ];

    lexer = new Lexer(input);
    foreach(index, token; tests) {
        auto tok = lexer.nextToken();
        
        assert(tok.type == token.type);
        assert(tok.literal == token.literal);
    }
}