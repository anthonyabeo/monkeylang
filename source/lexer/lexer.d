module lexer.lexer;

import std.stdio;
import std.conv;

import token.token;

/++

+/
struct Lexer {
    string input;        /// string to be tokenized
    size_t position;     /// current position in input (points to current char)
    size_t readPosition; /// current reading position in input (after current char)
    char ch;             /// current char under examination

    /++
        constructor for the lexer
    +/
    this(string input) {
        this.input = input;
        this.readChar();
    }

    /+++/
    void readChar() {
        if(this.readPosition >= this.input.length)
            this.ch = 0;
        else 
            this.ch = this.input[this.readPosition];

        this.position = this.readPosition;
        this.readPosition += 1;
    }

    /+++/
    char peekPosition() {
        if(this.readPosition >= this.input.length)
            return 0;
        else
            return this.input[this.readPosition];
    }

    /++
    
    +/
    Token nextToken() {
        Token tok;
        this.skipWhitespace();

        switch(this.ch) {
            case '=':
                if(this.peekPosition() == '=') {
                    auto ch = this.ch;
                    this.readChar();
                    auto literal = to!string(ch) ~ to!string(this.ch);
                    tok = Token(TokenType.EQ, literal);
                } else 
                    tok = Token(TokenType.ASSIGN, to!string(this.ch));
                break;
            case ';':
                tok = Token(TokenType.SEMICOLON, to!string(this.ch));
                break;
            case '(':
                tok = Token(TokenType.LPAREN, to!string(this.ch));
                break;
            case ')':
                tok = Token(TokenType.RPAREN, to!string(this.ch));
                break;
            case '{':
                tok = Token(TokenType.LBRACE, to!string(this.ch));
                break;
            case '}':
                tok = Token(TokenType.RBRACE, to!string(this.ch));
                break;
            case ',':
                tok = Token(TokenType.COMMA, to!string(this.ch));
                break;
            case '+':
                tok = Token(TokenType.PLUS, to!string(this.ch));
                break;
            case '-':
                tok = Token(TokenType.MINUS, to!string(this.ch));
                break;
            case '<':
                tok = Token(TokenType.LT, to!string(this.ch));
                break;
            case '>':
                tok = Token(TokenType.GT, to!string(this.ch));
                break;
            case '/':
                tok = Token(TokenType.SLASH, to!string(this.ch));
                break;
            case '!':
                if(this.peekPosition() == '=') {
                    auto ch = this.ch;
                    this.readChar();
                    auto literal = to!string(ch) ~ to!string(this.ch);
                    tok = Token(TokenType.NOT_EQ, literal);
                } else 
                    tok = Token(TokenType.BANG, to!string(this.ch));

                break;
            case '*':
                tok = Token(TokenType.ASTERISK, to!string(this.ch));
                break;
            case 0:
                tok.literal = "";
                tok.type = TokenType.EOF;
                break;
            case '"':
                tok.type = TokenType.STRING;
                tok.literal = this.readString();
                break;
            default:
                if (isLetter(this.ch)) {
                    tok.literal = readIdentifier();
                    tok.type = lookUpIndentifier(tok.literal);
                    return tok;
                } else if(isDigit(this.ch)) {
                    tok.type = TokenType.INT;
                    tok.literal = readNumber();
                    return tok;
                } else {
                    tok = Token(TokenType.ILLEGAL, to!string(this.ch));
                }
        }

        this.readChar();

        return tok;
    }

private:
    bool isLetter(char ch) {
        return ('a' <= ch && ch <= 'z') ||
               ('A' <= ch && ch <= 'Z') ||
               ch == '_';
    }

    string readIdentifier() {
        auto pos = this.position;
        while(isLetter(this.ch)) 
            this.readChar();
        
        return this.input[pos .. this.position];
    }

    void skipWhitespace() {
        while(this.ch == ' ' || this.ch == '\t' || this.ch == '\n' ||this.ch == '\r')
            this.readChar();
    }

    bool isDigit(char ch) {
        return '0' <= ch && ch <= '9';
    }

    string readNumber() {
        auto pos = this.position;
        while(isDigit(this.ch))
            this.readChar();
        
        return this.input[pos .. this.position];
    }

    string readString() {
        auto pos = this.position + 1;
        while(true) {
            this.readChar();
            if(this.ch == '"' || this.ch == 0)
                break;
        }

        return this.input[pos .. this.position];
    }
}