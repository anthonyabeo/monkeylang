module token.token;

/++

+/
enum TokenType {
    ILLEGAL,
    EOF,

    IDENTIFIER,
    INT,

    ASSIGN,
    PLUS,

    COMMA,
    SEMICOLON,

    LPAREN,
    RPAREN,
    LBRACE,
    RBRACE,

    // Keywords
    FUNCTION,
    LET
}

enum keywords = [
    "let": TokenType.LET,
    "fn": TokenType.FUNCTION
];

TokenType lookUpIndentifier(string ident) {
    if (ident in keywords) {
        return keywords[ident];
    }

    return TokenType.IDENTIFIER;
}

/++
    A struct to model the tokens
+/
struct Token {
    /// The type of the token
    TokenType type;
 
     /// Initial value of the token
    string literal;
}