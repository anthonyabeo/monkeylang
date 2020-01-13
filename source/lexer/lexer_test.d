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
             let result = add(five, ten);

             !-/*5;
             5 < 10 > 5;";
    
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
        Token(TokenType.BANG, "!"),
        Token(TokenType.MINUS, "-"),
        Token(TokenType.SLASH, "/"),
        Token(TokenType.ASTERISK, "*"),
        Token(TokenType.INT, "5"),
        Token(TokenType.SEMICOLON, ";"),
        Token(TokenType.INT, "5"),
        Token(TokenType.LT, "<"),
        Token(TokenType.INT, "10"),
        Token(TokenType.GT, ">"),
        Token(TokenType.INT, "5"),
        Token(TokenType.SEMICOLON, ";"),
        Token(TokenType.EOF, ""),
    ];

    lexer = new Lexer(input);
    foreach(index, token; tests) {
        auto tok = lexer.nextToken();
        
        assert(tok.type == token.type);
        assert(tok.literal == token.literal);
    }

    input = "if (5 < 10) {
                return true;
            } else {
                return false;
            }
            
            10 == 10;
            10 != 9;";

    tests = [
        Token(TokenType.IF, "if"),
        Token(TokenType.LPAREN, "("),
        Token(TokenType.INT, "5"),
        Token(TokenType.LT, "<"),
        Token(TokenType.INT, "10"),
        Token(TokenType.RPAREN, ")"),
        Token(TokenType.LBRACE, "{"),
        Token(TokenType.RETURN, "return"),
        Token(TokenType.TRUE, "true"),
        Token(TokenType.SEMICOLON, ";"),
        Token(TokenType.RBRACE, "}"),
        Token(TokenType.ELSE, "else"),
        Token(TokenType.LBRACE, "{"),
        Token(TokenType.RETURN, "return"),
        Token(TokenType.FALSE, "false"),
        Token(TokenType.SEMICOLON, ";"),
        Token(TokenType.RBRACE, "}"),
        Token(TokenType.INT, "10"),
        Token(TokenType.EQ, "=="),
        Token(TokenType.INT, "10"),
        Token(TokenType.SEMICOLON, ";"),
        Token(TokenType.INT, "10"),
        Token(TokenType.NOT_EQ, "!="),
        Token(TokenType.INT, "9"),
        Token(TokenType.SEMICOLON, ";"),
    ];

    lexer = new Lexer(input);
    foreach(index, token; tests) {
        auto tok = lexer.nextToken();
        
        assert(tok.type == token.type);
        assert(tok.literal == token.literal);
    }
}