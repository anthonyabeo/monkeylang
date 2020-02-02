module token.token;

/+++/
enum TokenType {
    ILLEGAL,
    EOF,

    IDENTIFIER,
    INT,
    STRING,

    // Operators
    ASSIGN,
    PLUS,
    MINUS,
    BANG,
    ASTERISK,
    SLASH,
    LT,
    GT,

    COMMA,
    SEMICOLON,
    LPAREN,
    RPAREN,
    LBRACE,
    RBRACE,
    EQ,
    NOT_EQ,
    LBRACKET,
    RBRACKET,
    COLON,

    // Keywords
    FUNCTION,
    LET,
    TRUE,
    FALSE,
    IF,
    ELSE,
    RETURN
}

///
TokenType[string] keywords;

static this() {
    keywords = [
        "let": TokenType.LET,
        "fn": TokenType.FUNCTION,
        "return": TokenType.RETURN,
        "true": TokenType.TRUE,
        "false": TokenType.FALSE,
        "if": TokenType.IF,
        "else": TokenType.ELSE
    ];
}


/+++/
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
    TokenType type; /// The type of the token
    string literal; /// Initial value of the token
}