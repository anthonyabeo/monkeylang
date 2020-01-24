module evaluator.eval;

import std.stdio;
import std.conv;

import ast.ast;
import objekt.objekt;

Boolean TRUE;   /// true
Boolean FALSE;  /// false
Null NULL;      /// null

static this() {
    NULL = new Null(); 
    TRUE = new Boolean(true),
    FALSE = new Boolean(false);
}

///
Objekt eval(Node node) {
    Objekt obj;
    auto nde = to!string(typeid((cast(Object)node)));

    switch(nde) {
        case "ast.ast.Program":
            obj = evalStatements((cast(Program)node).statements);
            break;
        case "ast.ast.ExpressionStatement":
            obj = eval((cast(ExpressionStatement)node).expression);
            break;

        // Expressions
        case "ast.ast.IntegerLiteral":
            obj = new Integer((cast(IntegerLiteral)node).value);
            break;
        case "ast.ast.BooleanLiteral":
            obj = nativeBoolToBooleanObject((cast(BooleanLiteral)node).value);
            break;
        case "ast.ast.PrefixExpression":
            auto prefixExprNode = cast(PrefixExpression) node;

            auto right = eval(prefixExprNode.right);
            obj = evalPrefixExpression(prefixExprNode.operator, right);
            break;
        default:
            obj = null;
    }

    return obj;
}

///
Objekt evalStatements(Statement[] statements) {
    Objekt obj;
    foreach(stmt; statements) {
        obj = eval(stmt);
    }

    return obj;
}

///
Boolean nativeBoolToBooleanObject(bool input) {
    if(input) return TRUE;
    return FALSE;
}

///
Objekt evalPrefixExpression(string operator, Objekt right) {
    switch(operator) {
        case "!":
            return evalBangOperatorExpression(right);
        default:
            return null;
    }
}

///
Objekt evalBangOperatorExpression(Objekt right) {
    if(right.inspect() == TRUE.inspect()) return FALSE;
    else if(right.inspect() == FALSE.inspect()) return TRUE;
    else if(right.inspect() == NULL.inspect()) return TRUE;
    else return FALSE;
}