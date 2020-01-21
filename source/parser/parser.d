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

/// Operator Precedence
enum precedence = [
    TokenType.EQ : OpPreced.EQUALS,
    TokenType.NOT_EQ : OpPreced.EQUALS,
    TokenType.LT : OpPreced.LESSGREATER,
    TokenType.GT : OpPreced.LESSGREATER,
    TokenType.PLUS : OpPreced.SUM,
    TokenType.MINUS : OpPreced.SUM,
    TokenType.SLASH : OpPreced.PRODUCT,
    TokenType.ASTERISK : OpPreced.PRODUCT,
    TokenType.LPAREN: OpPreced.CALL
];

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
        this.registerPrefixFxn(TokenType.IDENTIFIER, &this.parseIdentifier);
        this.registerPrefixFxn(TokenType.INT, &this.parseIntegerLiteral);
        this.registerPrefixFxn(TokenType.BANG, &this.parsePrefixExpression);
        this.registerPrefixFxn(TokenType.MINUS, &this.parsePrefixExpression);
        this.registerPrefixFxn(TokenType.TRUE, &this.parseBoolean);
        this.registerPrefixFxn(TokenType.FALSE, &this.parseBoolean);
        this.registerPrefixFxn(TokenType.LPAREN, &this.parseGroupedExpression);
        this.registerPrefixFxn(TokenType.IF, &this.parseIfExpression);
        this.registerPrefixFxn(TokenType.FUNCTION, &this.parseFunctionLiteral);

        this.infixParseFxns = (infixParseFn[TokenType]).init;
        this.registerInfixFxn(TokenType.PLUS, &this.parseInfixExpression);
        this.registerInfixFxn(TokenType.MINUS, &this.parseInfixExpression);
        this.registerInfixFxn(TokenType.SLASH, &this.parseInfixExpression);
        this.registerInfixFxn(TokenType.ASTERISK, &this.parseInfixExpression);
        this.registerInfixFxn(TokenType.EQ, &this.parseInfixExpression);
        this.registerInfixFxn(TokenType.NOT_EQ, &this.parseInfixExpression);
        this.registerInfixFxn(TokenType.LT, &this.parseInfixExpression);
        this.registerInfixFxn(TokenType.GT, &this.parseInfixExpression);
        this.registerInfixFxn(TokenType.LPAREN, &this.parseCallExpression);
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
    Expression parseCallExpression(Expression fxn) {
        auto exp = new CallExpression(this.curToken, fxn);
        exp.args = this.parseCallArguments();
        return exp;
    }

    /+++/
    Expression[] parseCallArguments() {
        Expression[] args;

        if(this.peekTokenIs(TokenType.RPAREN)) {
            this.nextToken();
            return args;
        }

        this.nextToken();
        args ~= this.parseExpression(OpPreced.LOWEST);

        while(this.peekTokenIs(TokenType.COMMA)) {
            this.nextToken();
            this.nextToken();
            args ~= this.parseExpression(OpPreced.LOWEST);
        }

        if(!this.expectPeek(TokenType.RPAREN))
            return null;

        return args;
    }

    /+++/
    Expression parseFunctionLiteral() {
        auto fnLit = new FunctionLiteral(this.curToken);
        if(!this.expectPeek(TokenType.LPAREN)) 
            return null;

        fnLit.parameters = this.parseFunctionParamters();

        if(!this.expectPeek(TokenType.LBRACE)) 
            return null;

        fnLit.fnBody = this.parseBlockStatement();

        return fnLit;
    }

    /+++/
    Identifier[] parseFunctionParamters() {
        Identifier[] identifiers;
        if(this.peekTokenIs(TokenType.RPAREN)) {
            this.nextToken();
            return identifiers;
        }

        this.nextToken();

        auto ident = new Identifier(this.curToken, this.curToken.literal);
        identifiers ~= ident;

        while(this.peekTokenIs(TokenType.COMMA)) {
            this.nextToken();
            this.nextToken();
            ident = new Identifier(this.curToken, this.curToken.literal);
            identifiers ~= ident;
        }

        if(!this.expectPeek(TokenType.RPAREN))
            return null;

        return identifiers;
    }

    /+++/
    Expression parseGroupedExpression() {
        this.nextToken();

        auto expr = parseExpression(OpPreced.LOWEST);
        if(!this.expectPeek(TokenType.RPAREN))
            return null;

        return expr;
    }

    /+++/
    Expression parseBoolean() {
        return new Boolean(this.curToken, this.curTokenIs(TokenType.TRUE));
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
    Expression parseIfExpression() {
        auto expr = new IfExpression(this.curToken);
        if(!this.expectPeek(TokenType.LPAREN))
            return null;

        this.nextToken();

        expr.condition = this.parseExpression(OpPreced.LOWEST);

        if(!this.expectPeek(TokenType.RPAREN))
            return null;

        if(!this.expectPeek(TokenType.LBRACE))
            return null;

        expr.consequence = this.parseBlockStatement();

        if(this.peekTokenIs(TokenType.ELSE)) {
            this.nextToken();
            if(!this.expectPeek(TokenType.LBRACE)) 
                return null;

            expr.alternative = this.parseBlockStatement();
        }

        return expr;
    }

    /+++/
    BlockStatement parseBlockStatement() {
        auto blckStmt = new BlockStatement(this.curToken);
        
        this.nextToken();

        while(!this.curTokenIs(TokenType.RBRACE) && !this.curTokenIs(TokenType.EOF)) {
            auto stmt = this.parseStatement();
            if(stmt !is null) 
                blckStmt.statements ~= stmt;

            this.nextToken();
        }

        return blckStmt;
    }

    /+++/
    Expression parseInfixExpression(Expression left) {
        auto expr = new InfixExpression(this.curToken, left, this.curToken.literal);
        
        auto prec = this.curPrecedence();
        this.nextToken();
        expr.right = this.parseExpression(prec);

        return expr;
    }

    /+++/
    Expression parsePrefixExpression() {
        auto expr = new PrefixExpression(this.curToken, this.curToken.literal);

        this.nextToken();
        expr.right = this.parseExpression(OpPreced.PREFIX);

        return expr;
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
        auto prefix = this.prefixParseFxns.get(this.curToken.type, null);
        if(prefix is null) {
            this.noPrefixParseFnError(this.curToken.literal);
            return null;
        }

        auto leftExp = prefix();
        
        while(!this.peekTokenIs(TokenType.SEMICOLON) && prec < this.peekPrecedence()) {
            auto infix = this.infixParseFxns.get(this.peekToken.type, null);
            if(infix is null)
                return leftExp;

            this.nextToken();
            leftExp = infix(leftExp);
        }

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

    /+++/
    OpPreced peekPrecedence() {
        if(this.peekToken.type in precedence) 
            return precedence[this.peekToken.type];

        return OpPreced.LOWEST;
    }

    /+++/
    OpPreced curPrecedence() {
        if(this.curToken.type in precedence)
            return precedence[this.curToken.type];

        return OpPreced.LOWEST;
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

        void noPrefixParseFnError(string tt) {
            this.errs ~= format("no prefix parse function for %s found", tt);
        }
}