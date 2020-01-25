module evaluator.eval;

import std.stdio;
import std.conv;
import std.string;

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
            obj = evalProgram(cast(Program) node);
            break;
        case "ast.ast.ExpressionStatement":
            obj = eval((cast(ExpressionStatement) node).expression);
            break;
        case "ast.ast.BlockStatement":
            auto blockStmt = cast(BlockStatement) node;

            obj = evalBlockStatement(blockStmt);
            break;
        case "ast.ast.IfExpression":
            auto ifExpr = cast(IfExpression) node;

            obj = evalIfExpression(ifExpr);
            break;
        case "ast.ast.ReturnStatement":
            auto retStmt = cast(ReturnStatement) node;
            auto val = eval(retStmt.returnValue);
            if(isError(val))
                return val;

            obj = new ReturnValue(val);
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
            if(isError(right))
                return right;

            obj = evalPrefixExpression(prefixExprNode.operator, right);
            break;
        case "ast.ast.InfixExpression":
            auto infixExprNode = cast(InfixExpression) node;

            auto left = eval(infixExprNode.left);
            if(isError(left))
                return left;

            auto right = eval(infixExprNode.right);
            if(isError(right))
                return right;

            obj = evalInfixExpression(infixExprNode.operator, left, right);
            break;
        default:
            obj = null;
    }

    return obj;
}

///
Objekt evalProgram(Program program) {
    Objekt obj;

    foreach(stmt; program.statements) {
        obj = eval(stmt);
        
        switch(obj.type()) {
            case ObjectType.RETURN_VALUE:
                auto retVal = cast(ReturnValue) obj;
                return retVal.value;
            case ObjectType.ERROR:
                return obj;
            default:
                break;
        }
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
            return newError("unknown operator: %s%s", operator, right.type());
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
        return newError("unknown operator: -%s", right.type());

    auto value = (cast(Integer)right).value;

    return new Integer(-value);
}

/+++/
Objekt evalInfixExpression(string operator, Objekt left, Objekt right) {
    if(left.type() == ObjectType.INTEGER && right.type() == ObjectType.INTEGER)
        return evalIntegerInfixExpression(operator, left, right);
    else if(operator == "==")
        return nativeBoolToBooleanObject(left == right);
    else if(operator == "!=")
        return nativeBoolToBooleanObject(left != right);
    else if(left.type() != right.type())
        return newError("type mismatch: %s %s %s", left.type(), operator, right.type());
    else
        return newError("unknown operator: %s %s %s", left.type(), operator, right.type());
}

/+++/
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
            return newError("unknown operator: %s %s %s", left.type(), operator, right.type());
    }
}

///
Objekt evalIfExpression(IfExpression ie) {
    auto condition = eval(ie.condition);
    if(isError(condition))
        return condition;
        
    if(isTruthy(condition)) 
        return eval(ie.consequence);        
    else if(ie.alternative !is null) 
        return eval(ie.alternative);
    else
        return NULL;
}

///
bool isTruthy(Objekt obj) {
    if(obj.inspect() == NULL.inspect()) return false;
    else if(obj.inspect() == TRUE.inspect())  return true;
    else if(obj.inspect() == FALSE.inspect()) return false;
    else return true;
}

/+++/
Objekt evalBlockStatement(BlockStatement block) {
    Objekt obj;
    foreach (stmt; block.statements) {
        obj = eval(stmt);

        if(obj !is null) {
            auto type = obj.type();
            if((type == ObjectType.RETURN_VALUE) || (type == ObjectType.ERROR))
                return obj;
        }
    }

    return obj;
}

///
Err newError(T...) (string fmt, T args) {
    return new Err(format(fmt, args));
}

///
bool isError(Objekt obj) {
    if(obj !is null)
        return obj.type() == ObjectType.ERROR;

    return false;
}