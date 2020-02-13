module evaluator.builtins;

import std.stdio;
import std.conv;
import std.string;

import objekt.objekt;
import objekt.builtins;
import ast.ast : Identifier;
import objekt.environment : Environment;

Boolean TRUE;   /// true
Boolean FALSE;  /// false
Null NULL;      /// null

BuiltIn[string] builtins; /// BuiltIn bin;

static this() {
    NULL = new Null(); 
    TRUE = new Boolean(true),
    FALSE = new Boolean(false);

    builtins = [
        "len" : getBuiltinByName("len"),
        "first" : getBuiltinByName("first"),
        "last" : getBuiltinByName("last"),
        "rest" : getBuiltinByName("rest"),
        "push" : getBuiltinByName("push"),
        "puts" : getBuiltinByName("puts"),
    ];
}

///
Err newError(T...) (string fmt, T args) {
    return new Err(format(fmt, args));
}

/+++/
Objekt evalIdentifier(Identifier node, Environment env) {
    auto val = env.get(node.value);
    if(val !is null)
        return val;
    
    auto builtin = builtins.get(node.value, null);
    if(builtin !is null) 
        return builtin;

    return newError("identifier not found: " ~ node.value);
}