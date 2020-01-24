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
            obj = evalStatements((cast(Program) node).statements);
            break;
        case "ast.ast.ExpressionStatement":
            obj = eval((cast(ExpressionStatement) node).expression);
            break;
        case "ast.ast.BlockStatement":
            auto blockStmt = cast(BlockStatement) node;

            obj = evalStatements(blockStmt.statements);
            break;
        case "ast.ast.IfExpression":
            auto ifExpr = cast(IfExpression) node;

            obj = evalIfExpression(ifExpr);
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
        case "ast.ast.InfixExpression":
            auto infixExprNode = cast(InfixExpression) node;

            auto left = eval(infixExprNode.left);
            auto right = eval(infixExprNode.right);
            
            obj = evalInfixExpression(infixExprNode.operator, left, right);
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
        case "-":
            return evalMinusOperatorExpression(right);
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

///
Objekt evalMinusOperatorExpression(Objekt right) {
    if(right.type() != ObjectType.INTEGER)
        return null;

    auto value = (cast(Integer)right).value;

    return new Integer(-value);
}

Objekt evalInfixExpression(string operator, Objekt left, Objekt right) {
    if(left.type() == ObjectType.INTEGER && right.type() == ObjectType.INTEGER)
        return evalIntegerInfixExpression(operator, left, right);
    else if(operator == "==")
        return nativeBoolToBooleanObject(left == right);
    else if(operator == "!=")
        return nativeBoolToBooleanObject(left != right);
    else
        return NULL;
}

Objekt evalIntegerInfixExpression(string operator, Objekt left, Objekt right) {
    auto leftVal = (cast(Integer) left).value;
    auto rightVal = (cast(Integer) right).value;

    switch(operator) {
        case "+":
            return new Integer(leftVal + rightVal);
        case "-":
            return new Integer(leftVal - rightVal);
        case "*":
            return new Integer(leftVal * rightVal);
        case "/":
            return new Integer(leftVal / rightVal);
        case "<":
            return nativeBoolToBooleanObject(leftVal < rightVal);
        case ">":
            return nativeBoolToBooleanObject(leftVal > rightVal);
        case "==":
            return nativeBoolToBooleanObject(leftVal == rightVal);
        case "!=":
            return nativeBoolToBooleanObject(leftVal != rightVal);
        default:
            return NULL;
    }
}

Objekt evalIfExpression(IfExpression ie) {
    auto condition = eval(ie.condition);
    if(isTruthy(condition)) 
        return eval(ie.consequence);        
    else if(ie.alternative !is null) 
        return eval(ie.alternative);
    else
        return NULL;
}

bool isTruthy(Objekt obj) {
    if(obj.inspect() == NULL.inspect()) return false;
    else if(obj.inspect() == TRUE.inspect())  return true;
    else if(obj.inspect() == FALSE.inspect()) return false;
    else return true;
}