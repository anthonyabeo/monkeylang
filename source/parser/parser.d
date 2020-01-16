module parser.parser;

import std.stdio;
import std.string;
import std.conv;

import token.token;
import lexer.lexer;
import ast.ast;

alias prefixParseFn = Expression delegate();
alias infixParseFn = Expression delegate(Expression);

/// Operator Precedence Rules
enum OpPreced : ubyte {
    LOWEST = 0,
    EQUALS,         // ==
    LESSGREATER,    // > or <
    SUM,            // +
    PRODUCT,        // *
    PREFIX,         // -X or !X
    CALL            // myFunction(X)
}

/+++/
struct Parser {
    Lexer lex;          /// the lexer to retrieve tokens from.
    Token curToken;     /// provides access to the current token
    Token peekToken;    /// allows us to look ahead for tokens after curToken
    string[] errs;     /// collection of error ecountered.
    prefixParseFn[TokenType] prefixParseFxns;  /// mapping of prefix tokens to their parse fnxs
    infixParseFn[TokenType] infixParseFxns;    /// mapping of infix tokens to their parse fnxs

    /***********************************
    * Constructor for the Parser.
    *
    * Params:
    *      lex =  is for the lexer this parser calls to retrieve the next token
    */
    this(ref Lexer lex) {
        this.lex = lex;
        this.errs = [];

        // Read two tokens, so curToken and peekToken are both set
        this.nextToken();
        this.nextToken();

        this.prefixParseFxns = (prefixParseFn[TokenType]).init;
        this.registerPrefixFxn(TokenType.IDENTIFIER, &Parser.parseIdentifier);
        this.registerPrefixFxn(TokenType.INT, &Parser.parseIntegerLiteral);
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
    Expression parseIntegerLiteral() {
        auto iLit = new IntegerLiteral(this.curToken);
        long value;

        try {
            value = to!long(this.curToken.literal);
        } catch (ConvException ce) {
            this.errs ~= format("could not parse %s as integer", this.curToken.literal);
            return null;
        }
        
        iLit.value = value;

        return iLit;
    }

    /+++/
    Expression parseIdentifier() {
        return new Identifier(this.curToken, this.curToken.literal);
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
            case TokenType.RETURN:
                stmt = this.parseReturnStatement();
                break;
            default:
                stmt = this.parseExpressionStatement();
        }

        return stmt;
    }

    /+++/
    ExpressionStatement parseExpressionStatement() {
        auto expStmt = new ExpressionStatement(this.curToken);
        expStmt.expression = this.parseExpression(OpPreced.LOWEST);
        if(this.peekTokenIs(TokenType.SEMICOLON))
            this.nextToken();

        return expStmt;
    }

    /+++/
    Expression parseExpression(OpPreced prec) {
        auto prefix = this.prefixParseFxns[this.curToken.type];
        if(prefix is null) 
            return null;

        auto leftExp = prefix();

        return leftExp;
    }

    /+++/
    ReturnStatement parseReturnStatement() {
        auto stmt = new ReturnStatement(this.curToken);
        this.nextToken();

        // TODO: We're skipping the expressions until we
        // encounter a semicolon

        while(!this.curTokenIs(TokenType.SEMICOLON))
            this.nextToken();

        return stmt;
    }

    /+++/
    LetStatement parseLetStatement() {
        auto stmt = new LetStatement(this.curToken);
        if(!this.expectPeek(TokenType.IDENTIFIER))
            return null;

        stmt.name = new Identifier(this.curToken, this.curToken.literal);

        if(!this.expectPeek(TokenType.ASSIGN))
            return null;

        // TODO: We're skipping the expressions until we
        // encounter a semicolon

        while(!this.curTokenIs(TokenType.SEMICOLON))
            this.nextToken();

        return stmt;
    }

    /+++/
    void registerPrefixFxn(TokenType tt, prefixParseFn fxn) {
        this.prefixParseFxns[tt] = fxn;
    }

    /+++/
    void registerInfixFxn(TokenType tt, infixParseFn fnx) {
        this.infixParseFxns[tt] = fnx;
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