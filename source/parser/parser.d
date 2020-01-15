module parser.parser;

import std.stdio;
import std.string;

import token.token;
import lexer.lexer;
import ast.ast;


/+++/
struct Parser {
    Lexer lex;          /// the lexer to retrieve tokens from.
    Token curToken;     /// provides access to the current token
    Token peekToken;    /// allows us to look ahead for tokens after curToken
    string[] errs;     /// collection of error ecountered.

    /***********************************
    * Constructor for the Parser.
    *
    * Params:
    *      lex =  is for the lexer this parser calls to retrieve the next token
    */
    this(ref Lexer lex) {
        this.lex = lex;
        this.errs = new string[0];

        // Read two tokens, so curToken and peekToken are both set
        this.nextToken();
        this.nextToken();
    }

    /// postblit constructor
    this(this) {
        this.errs = errs.dup;
    }

    /***/
    string[] errors() {
        return this.errs;
    }

    /+++/
    void nextToken() {
        this.curToken = this.peekToken;
        this.peekToken = this.lex.nextToken();
    }

    /+++/
    Program parseProgram() {
        auto program = new Program();

        while(this.curToken.type != TokenType.EOF) {
            auto stmt = this.parseStatement();
            if(stmt !is null) {
                program.statements ~= stmt;
            }

            this.nextToken();
        }

        return program;
    }

    /+++/
    Statement parseStatement() {
        Statement stmt;

        switch(this.curToken.type) {
            case TokenType.LET:
                stmt = this.parseLetStatement();
                break;
            default:
                stmt = null;
        }

        return stmt;
    }

    /+++/
    LetStatement parseLetStatement() {
        auto stmt = new LetStatement(this.curToken);
        if(!this.expectPeek(TokenType.IDENTIFIER))
            return null;

        stmt.name = Identifier(this.curToken, this.curToken.literal);

        if(!this.expectPeek(TokenType.ASSIGN))
            return null;

        // TODO: We're skipping the expressions until we
        // encounter a semicolon

        while(!this.curTokenIs(TokenType.SEMICOLON))
            this.nextToken();

        return stmt;
    }

    private:
        bool curTokenIs(TokenType tt) {
            return this.curToken.type == tt;
        }

        bool peekTokenIs(TokenType tt) {
            return this.peekToken.type == tt;
        }

        bool expectPeek(TokenType tt) {
            if(this.peekTokenIs(tt)) {
                this.nextToken();
                return true;
            }

            this.peekError(tt);
            return false;
        }

        void peekError(TokenType tt) {
            auto msg = format("expected next token to be %s, got %s instead", 
                              tt, this.peekToken.type);
            this.errs ~= msg;
        }
}