module evaluator.eval;

import std.stdio;
import std.conv;
import std.string;
import core.exception;

import ast.ast;
import objekt.objekt;
import objekt.environment;
import evaluator.builtins;

///
Objekt eval(Node node, Environment env) {
    Objekt obj;
    auto nde = to!string(typeid((cast(Object)node)));

    switch(nde) {
        case "ast.ast.Program":
            obj = evalProgram(cast(Program) node, env);
            break;
        case "ast.ast.ExpressionStatement":
            obj = eval((cast(ExpressionStatement) node).expression, env);
            break;
        case "ast.ast.BlockStatement":
            auto blockStmt = cast(BlockStatement) node;

            obj = evalBlockStatement(blockStmt, env);
            break;
        case "ast.ast.IfExpression":
            auto ifExpr = cast(IfExpression) node;

            obj = evalIfExpression(ifExpr, env);
            break;
        case "ast.ast.ReturnStatement":
            auto retStmt = cast(ReturnStatement) node;
            auto val = eval(retStmt.returnValue, env);
            if(isError(val))
                return val;

            obj = new ReturnValue(val);
            break;
        case "ast.ast.LetStatement":
            auto letStmt = cast(LetStatement) node;
            auto val = eval(letStmt.value, env);
            if(isError(val))
                return val;

            env.set(letStmt.name.value, val);

            obj = new Null();
            break;
        case "ast.ast.Identifier":
            auto ident = cast(Identifier) node;

            obj = evalIdentifier(ident, env);
            break;
        case "ast.ast.FunctionLiteral":
            auto fn = cast(FunctionLiteral) node;

            auto params = fn.parameters;
            auto fnBody = fn.fnBody;

            obj = new Function(params, env, fnBody);
            break;
        case "ast.ast.CallExpression":
            auto callExpr = cast(CallExpression) node;

            auto fn = eval(callExpr.fxn, env);
            if(isError(fn))
                return fn;

            auto args = evalExpressions(callExpr.args, env);
            if(args.length == 1 && isError(args[0]))
                return args[0];

            return applyFunction(fn, args);
        case "ast.ast.IndexExpression":
            auto indexExp = cast(IndexExpression) node;
            auto left = eval(indexExp.left, env);
            if(isError(left))
                return left;

            auto index = eval(indexExp.index, env);
            if(isError(index))
                return index;

            return evalIndexExpression(left, index);
        case "ast.ast.HashLiteral":
            auto hashLitNode = cast(HashLiteral) node;
            return evalHashLiteral(hashLitNode, env);
        case "ast.ast.ArrayLiteral":
            auto arrLitNode = cast(ArrayLiteral) node;

            auto elements = evalExpressions(arrLitNode.elements, env);
            if(elements.length == 1 && isError(elements[0]))
                return elements[0];
            
            obj = new Array(elements);
            break;
        case "ast.ast.IntegerLiteral":
            obj = new Integer((cast(IntegerLiteral) node).value);
            break;
        case "ast.ast.StringLiteral":
            obj = new String((cast(StringLiteral) node).value);
            break;
        case "ast.ast.BooleanLiteral":
            obj = nativeBoolToBooleanObject((cast(BooleanLiteral)node).value);
            break;
        case "ast.ast.PrefixExpression":
            auto prefixExprNode = cast(PrefixExpression) node;

            auto right = eval(prefixExprNode.right, env);
            if(isError(right))
                return right;

            obj = evalPrefixExpression(prefixExprNode.operator, right);
            break;
        case "ast.ast.InfixExpression":
            auto infixExprNode = cast(InfixExpression) node;

            auto left = eval(infixExprNode.left, env);
            if(isError(left))
                return left;

            auto right = eval(infixExprNode.right, env);
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
Objekt evalProgram(Program program, Environment env) {
    Objekt obj;

    foreach(stmt; program.statements) {
        obj = eval(stmt, env);

        switch(obj.type()) {
            case ObjectType.RETURN_VALUE:
                auto retVal = cast(ReturnValue) obj;
                return retVal.value;
            case ObjectType.ERROR:
                return obj;
            default:
                continue;
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
    else if(left.type() == ObjectType.STRING && right.type() == ObjectType.STRING)
        return evalStringInfixExpression(operator, left, right);
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
Objekt evalStringInfixExpression(string operator, Objekt left, Objekt right) {
    if(operator != "+")
        return newError("unknown operator: %s %s %s", left.type(), operator, right.type());
    
    auto leftVal = (cast(String) left).value;
    auto rightVal = (cast(String) right).value;
    
    return new String(leftVal ~ rightVal);
}

///
Objekt evalIfExpression(IfExpression ie, Environment env) {
    auto condition = eval(ie.condition, env);
    if(isError(condition))
        return condition;

    if(isTruthy(condition)) 
        return eval(ie.consequence, env);        
    else if(ie.alternative !is null) 
        return eval(ie.alternative, env);
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
Objekt evalBlockStatement(BlockStatement block, Environment env) {
    Objekt obj;
    foreach (stmt; block.statements) {
        obj = eval(stmt, env);

        if(obj !is null) {
            auto type = obj.type();
            if((type == ObjectType.RETURN_VALUE) || (type == ObjectType.ERROR))
                return obj;
        }
    }

    return obj;
}

// ///
// Err newError(T...) (string fmt, T args) {
//     return new Err(format(fmt, args));
// }

///
bool isError(Objekt obj) {
    if(obj !is null)
        return obj.type() == ObjectType.ERROR;

    return false;
}

///
Objekt[] evalExpressions(Expression[] exps, Environment env) {
    Objekt[] result;

    foreach(e; exps) {
        auto evaluated = eval(e, env);
        if(isError(evaluated))
            return [evaluated];
        result ~= evaluated;
    }

    return result;
}

/***********************************
* applyFunction
*/
Objekt applyFunction(Objekt fxn, Objekt[] args) {
    switch(fxn.type()) {
        case ObjectType.FUNCTION:
            auto fn = cast(Function) fxn;

            if(fn is null) {
                return newError("not a function: %s", fn.type());
            }

            auto extendedEnv = extendFunctionEnv(fn, args);
            auto evaluated = eval(fn.fnBody, extendedEnv);

            return unwrapReturnValue(evaluated);
        case ObjectType.BUILTIN:
            auto fn = cast(BuiltIn) fxn;
            
            auto result = fn.fxn(args);
            if(result !is null)
                return result;

            return NULL;
        default:
            return newError("not a function: %s", fxn.type());
    }
}

///
Environment extendFunctionEnv(Function fn, Objekt[] args) {
    auto env = Environment.newEnclosingEnvironment(fn.env);
    foreach(paramIdx, param; fn.parameters) {
        env.set(param.value, args[paramIdx]);
    }

    return env;
}

///
Objekt unwrapReturnValue(Objekt obj) {
    auto retValue = cast(ReturnValue) obj;
    if(retValue !is null)
        return retValue.value;

    return obj;
}

///
Objekt evalIndexExpression(Objekt left, Objekt index) {
    if(left.type() == ObjectType.ARRAY && index.type() == ObjectType.INTEGER)
        return evalArrayIndexExpression(left, index);
    else if(left.type() == ObjectType.HASH)
        return evalHashIndexExpression(left, index);
    else
        return newError("index operator not supported: %s", left.type());
}

///
Objekt evalArrayIndexExpression(Objekt array, Objekt index) {
    auto arrayObject = cast(Array) array;
    auto idx = (cast(Integer) index).value ;
    const max = to!size_t(arrayObject.elements.length - 1);

    if(idx < 0 || idx > max)
        return NULL;
    
    return arrayObject.elements[idx];
}

///
Objekt evalHashLiteral(HashLiteral node, Environment env) {
    auto pairs = (HashPair[HashKey]).init;
    foreach(keyNode, valueNode; node.pairs) {
        auto key = eval(keyNode, env);
        if(isError(key))
            return key;

        auto hashKey = cast(Hashable) key;
        if(hashKey is null)
            return newError("unusable as hash key: %s", key.type());

        auto value = eval(valueNode, env);
        if(isError(value))
            return value;

        auto hashed = hashKey.hashKey();
        pairs[hashed] = HashPair(key, value);
    }

    return new Hash(pairs);
}

///
Objekt evalHashIndexExpression(Objekt hash, Objekt index) {
    auto hashObj = cast(Hash) hash;
    auto key = cast(Hashable) index;
    if(key is null)
        return newError("unusable as hash key: %s", index.type());

    HashPair pair;
    try {
        pair = hashObj.pairs[key.hashKey()];
    }
    catch(RangeError re) {
        return NULL;
    }

    return pair.value;
}