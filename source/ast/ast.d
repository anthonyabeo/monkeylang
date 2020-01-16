module ast.ast;

import token.token;

/+++/
interface Node {

    /+++/
    string tokenLiteral();

    /+++/
    string asString();
}

/+++/
interface Statement : Node {

    /+++/
    void statementNode();
}


/+++/
interface Expression : Node {

    /+++/
    void expressionNode();
}

/+++/
class Program {
    Statement[] statements; /// a program is a bunch of statements

    /***********************************
     * Constructor
     */
    this() {
        this.statements = [];
    }

    /+++/
    string tokenLiteral() {
        if(this.statements.length > 0)
            return this.statements[0].tokenLiteral();
        return "";
    }

    /+++/
    string asString() {
        string outBuffer;
        foreach (stmt; this.statements) {
            outBuffer ~= stmt.asString();
        }

        return outBuffer;
    }
}

/+++/
class Identifier : Expression {
    Token token;    /// the IDENTIFIER token type
    string value;   /// the value (name) if this identifier.

    /+++/
    this(Token token, string value) {
        this.token = token;
        this.value = value;
    }

    /***********************************
     * expressionNode does nothing in particular.
     */
    void expressionNode()  {}

    /+++/
    string tokenLiteral() {
        return this.token.literal;
    }

    /+++/
    string asString() {
        return this.value;
    }
}

/+++/
class ExpressionStatement : Statement {
    Token token;             /// the first token of the expression
    Expression expression;  ///  expression

    /***********************************
     * statementNode does nothing in particular. 
     * mostly used for debugging purposes.
     */
    void statementNode() {}

    /+++/
    string tokenLiteral() {
        return this.token.literal;
    }

    /+++/
    string asString() {
        if(this.expression !is null)
            return this.expression.asString();
        return "";
    }
}

/+++/
class LetStatement : Statement {
    Token token;      /// the LET token type.
    Expression value; ///  the expression that produces a value to be bound
    Identifier name;  /// idenifier for the bound

    /***********************************
     * Constructor
     */
    this(Token token) {
        this.token = token;
    }

    /***********************************
     * statementNode does nothing in particular. 
     * mostly used for debugging purposes.
     */
    void statementNode() {}

    /+++/
    string tokenLiteral() {
        return this.token.literal;
    }

    /+++/
    string asString() {
        string outBuffer = this.tokenLiteral() ~ " " ~ this.name.asString() ~ " = ";
        if(this.value !is null)
            outBuffer ~= this.value.asString();

        outBuffer ~= ";";

        return outBuffer;
    }
}

/+++/
class ReturnStatement : Statement {
    Token token;                /// the 'return' token
    Expression returnValue;     /// the value of the expression to be returned

    /***********************************
     * Constructor
     */
    this(Token token) {
        this.token = token;
    }

    /+++/
    void statementNode() {}

    /+++/
    string tokenLiteral() {
        return this.token.literal;
    }

    /+++/
    string asString() {
        string outBuffer = this.tokenLiteral() ~ " ";
        if(this.returnValue !is null)
            outBuffer ~= this.returnValue.asString();
        
        outBuffer ~= ";";

        return outBuffer;
    }
}

