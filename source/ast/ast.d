module ast.ast;

import token.token;

/+++/
interface Node {

    /+++/
    string tokenLiteral();
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
     * foo does this.
     * Params:
     *      stmts =     an array of Statements
     */
    this() {
        this.statements = [];
    }

    // this(this) {
    //     statements = statements.dup;
    // }

    /+++/
    string tokenLiteral() {
        if(this.statements.length > 0)
            return this.statements[0].tokenLiteral();
        return "";
    }
}

/+++/
struct Identifier {
    Token token;    /// the IDENTIFIER token type
    string value;   /// the value (name) if this identifier.

    /***********************************
     * expressionNode does nothing in particular.
     */
    void expressionNode()  {}

    /+++/
    string tokenLiteral() {
        return this.token.literal;
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
}

