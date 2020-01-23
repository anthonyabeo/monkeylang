module evaluator.eval;

import std.stdio;
import std.conv;

import ast.ast;
import objekt.objekt;

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