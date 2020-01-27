module parser.parser;

import std.stdio;
import std.string;
import std.conv;

import token.token;
import lexer.lexer;
import ast.ast;

alias prefixParseFn = Expression function(ref Parser);
alias infixParseFn = Expression function(ref Parser, ref Expression);

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
        this.registerPrefixFxn(TokenType.IDENTIFIER, &Parser.parseIdentifier);
        this.registerPrefixFxn(TokenType.INT, &Parser.parseIntegerLiteral);
        this.registerPrefixFxn(TokenType.BANG, &Parser.parsePrefixExpression);
        this.registerPrefixFxn(TokenType.MINUS, &Parser.parsePrefixExpression);
        this.registerPrefixFxn(TokenType.TRUE, &Parser.parseBoolean);
        this.registerPrefixFxn(TokenType.FALSE, &Parser.parseBoolean);
        this.registerPrefixFxn(TokenType.LPAREN, &Parser.parseGroupedExpression);
        this.registerPrefixFxn(TokenType.IF, &Parser.parseIfExpression);
        this.registerPrefixFxn(TokenType.FUNCTION, &Parser.parseFunctionLiteral);
        this.registerPrefixFxn(TokenType.STRING, &Parser.parseStringLiteral);
        this.registerPrefixFxn(TokenType.LBRACKET, &Parser.parseArrayLiteral);

        this.infixParseFxns = (infixParseFn[TokenType]).init;
        this.registerInfixFxn(TokenType.PLUS, &Parser.parseInfixExpression);
        this.registerInfixFxn(TokenType.MINUS, &Parser.parseInfixExpression);
        this.registerInfixFxn(TokenType.SLASH, &Parser.parseInfixExpression);
        this.registerInfixFxn(TokenType.ASTERISK, &Parser.parseInfixExpression);
        this.registerInfixFxn(TokenType.EQ, &Parser.parseInfixExpression);
        this.registerInfixFxn(TokenType.NOT_EQ, &Parser.parseInfixExpression);
        this.registerInfixFxn(TokenType.LT, &Parser.parseInfixExpression);
        this.registerInfixFxn(TokenType.GT, &Parser.parseInfixExpression);
        this.registerInfixFxn(TokenType.LPAREN, &Parser.parseCallExpression);
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
    static Expression parseArrayLiteral(ref Parser parser) {
        auto array = new ArrayLiteral(parser.curToken);

        array.elements = parser.parseExpressionList(TokenType.RBRACKET);

        return array;
    }

    /+++/
    Expression[] parseExpressionList(TokenType endToken) {
        Expression[] expList;

        if(this.peekTokenIs(endToken)) {
            this.nextToken();
            return expList;
        }

        this.nextToken();
        expList ~= this.parseExpression(OpPreced.LOWEST);

        while(this.peekTokenIs(TokenType.COMMA)) {
            this.nextToken();
            this.nextToken();
            expList ~= this.parseExpression(OpPreced.LOWEST);
        }

        if(!this.expectPeek(endToken))
            return null;

        return expList;
    }

    /+++/
    static Expression parseCallExpression(ref Parser parser, ref Expression fxn) {
        auto exp = new CallExpression(parser.curToken, fxn);
        exp.args = parser.parseExpressionList(TokenType.RPAREN);
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
    static Expression parseFunctionLiteral(ref Parser parser) {
        auto fnLit = new FunctionLiteral(parser.curToken);
        if(!parser.expectPeek(TokenType.LPAREN)) 
            return null;

        fnLit.parameters = parser.parseFunctionParamters();

        if(!parser.expectPeek(TokenType.LBRACE)) 
            return null;

        fnLit.fnBody = parser.parseBlockStatement();

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
    static Expression parseGroupedExpression(ref Parser parser) {
        parser.nextToken();

        auto expr = parser.parseExpression(OpPreced.LOWEST);
        if(!parser.expectPeek(TokenType.RPAREN))
            return null;

        return expr;
    }

    /+++/
    static Expression parseBoolean(ref Parser parser) {
        return new BooleanLiteral(parser.curToken, parser.curTokenIs(TokenType.TRUE));
    }

    /+++/
    static Expression parseIntegerLiteral(ref Parser parser) {
        auto iLit = new IntegerLiteral(parser.curToken);
        long value;

        try {
            value = parse!long(parser.curToken.literal);
        } catch (ConvException ce) {
            parser.errs ~= format("could not parse %s as integer", parser.curToken.literal);
            return null;
        }

        iLit.value = value;

        return iLit;
    }

    /+++/
    static Expression parseStringLiteral(ref Parser parser) {
        return new StringLiteral(parser.curToken, parser.curToken.literal);
    }

    /+++/
    static Expression parseIdentifier(ref Parser parser) {
        return new Identifier(parser.curToken, parser.curToken.literal);
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
    static Expression parseIfExpression(ref Parser parser) {
        auto expr = new IfExpression(parser.curToken);
        if(!parser.expectPeek(TokenType.LPAREN))
            return null;

        parser.nextToken();

        expr.condition = parser.parseExpression(OpPreced.LOWEST);

        if(!parser.expectPeek(TokenType.RPAREN))
            return null;

        if(!parser.expectPeek(TokenType.LBRACE))
            return null;

        expr.consequence = parser.parseBlockStatement();

        if(parser.peekTokenIs(TokenType.ELSE)) {
            parser.nextToken();
            if(!parser.expectPeek(TokenType.LBRACE)) 
                return null;

            expr.alternative = parser.parseBlockStatement();
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
    static Expression parseInfixExpression(ref Parser parser, ref Expression left) {
        auto expr = new InfixExpression(parser.curToken, left, parser.curToken.literal);
        
        auto prec = parser.curPrecedence();
        parser.nextToken();
        expr.right = parser.parseExpression(prec);

        return expr;
    }

    /+++/
    static Expression parsePrefixExpression(ref Parser parser) {
        auto expr = new PrefixExpression(parser.curToken, parser.curToken.literal);

        parser.nextToken();
        expr.right = parser.parseExpression(OpPreced.PREFIX);

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
            this.noPrefixParseFnError(this.curToken.type);
            return null;
        }

        auto leftExp = prefix(this);
        
        while(!this.peekTokenIs(TokenType.SEMICOLON) && prec < this.peekPrecedence()) {
            auto infix = this.infixParseFxns.get(this.peekToken.type, null);
            if(infix is null)
                return leftExp;

            this.nextToken();
            leftExp = infix(this, leftExp);
        }

        return leftExp;
    }

    /+++/
    ReturnStatement parseReturnStatement() {
        auto stmt = new ReturnStatement(this.curToken);
        this.nextToken();

        stmt.returnValue = this.parseExpression(OpPreced.LOWEST);

        if(this.peekTokenIs(TokenType.SEMICOLON))
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

        this.nextToken();
        
        stmt.value = this.parseExpression(OpPreced.LOWEST);

        if(this.peekTokenIs(TokenType.SEMICOLON))
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

        void noPrefixParseFnError(TokenType tt) {
            this.errs ~= format("no prefix parse function for %s found", tt);
        }
}