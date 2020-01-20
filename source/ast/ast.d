module ast.ast;

import std.string;

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

class Boolean : Expression {
    Token token;
    bool value;

    this(Token token, bool value) {
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
        return this.token.literal;
    }
}

/+++/
class IntegerLiteral : Expression {
    Token token;    /// the INT token type
    ulong value;    /// value

    /***********************************
     * Constructor
     */
    this(Token token) {
        this.token = token;
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
        return this.token.literal;
    }
}

/+++/
class IfExpression : Expression {
    Token token;                /// token
    Expression condition;       /// condition of the if expression
    BlockStatement consequence; /// block state fot the if-clause
    BlockStatement alternative; /// block statement for the else-clause

    /+++/
    this(Token token) {
        this.token = token;
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
        string s = format("if%s %s", this.condition.asString(), 
                                     this.consequence.asString());
        if(this.alternative !is null)
            s ~= "else " ~ this.alternative.asString();

        return s;
    }
}

/+++/
class InfixExpression : Expression {
    Token token;        /// token
    Expression left;    /// left
    string operator;    /// operator
    Expression right;   /// right

    /+++/
    this(Token token, Expression left, string operator) {
        this.token = token;
        this.left = left;
        this.operator = operator;
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
        string s = format("(%s %s %s)", this.left.asString(), 
                                        this.operator, 
                                        this.right.asString());
        return s;
    }
}

/+++/   
class PrefixExpression : Expression {
    Token token;        /// token
    string operator;    /// operator
    Expression right;   /// the right expression node

    /+++/
    this(Token token, string operator) {
        this.token = token;
        this.operator = operator;
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
        string buffer = "(" ~ this.operator ~ this.right.asString() ~ ")";
        return buffer;
    }
}

/+++/
class Identifier : Expression {
    Token token;    /// the IDENTIFIER token type
    string value;   /// the value (name) of this identifier.

    /***********************************
     * Constructor
     */
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
class BlockStatement : Statement {
    Token token;            /// token
    Statement[] statements; /// array of statements in this block

    /+++/
    this(Token token) {
        this.token = token;
        this.statements = [];
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
        string s;
        foreach(stmt; this.statements) {
            s ~= stmt.asString();
        }

        return s;
    }
}

/***********************************
 * Expression Statement
 */
class ExpressionStatement : Statement {
    Token token;             /// the first token of the expression
    Expression expression;  ///  expression

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

