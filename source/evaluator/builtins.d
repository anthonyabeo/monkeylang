module evaluator.builtins;

import std.stdio;
import std.conv;
import std.string;

import objekt.objekt;
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
        "len" :  new BuiltIn(
                function Objekt(Objekt[] args...) { 
                    if(args.length != 1) 
                        return newError("wrong number of arguments. got=%d, want=1", args.length);

                    switch(args[0].type()) {
                        case ObjectType.STRING:
                            auto arg = cast(String) args[0];
                            return new Integer(to!long(arg.value.length));
                        case ObjectType.ARRAY:
                            auto arg = cast(Array) args[0];
                            return new Integer(to!long(arg.elements.length));
                        default: 
                            return newError("argument to `len` not supported, got %s", args[0].type());
                    }
                }
            ),

        "first" : new BuiltIn(
                function Objekt(Objekt[] args...) { 
                    if(args.length != 1) 
                        return newError("wrong number of arguments. got=%d, want=1", args.length);

                    if(args[0].type() != ObjectType.ARRAY) 
                        return newError("argument to `first` must be ARRAY, got %s", args[0].type());

                    auto arr = cast(Array) args[0];
                    if(arr.elements.length > 0)
                        return arr.elements[0];

                    return NULL;
                }
            ),

        "last" : new BuiltIn(
                function Objekt(Objekt[] args...) { 
                    if(args.length != 1) 
                        return newError("wrong number of arguments. got=%d, want=1", args.length);

                    if(args[0].type() != ObjectType.ARRAY) 
                        return newError("argument to `last` must be ARRAY, got %s", args[0].type());

                    auto arr = cast(Array) args[0];
                    auto len = arr.elements.length;
                    if(len > 0)
                        return arr.elements[len-1];
                    
                    return NULL;
                }
            ),

        "rest" : new BuiltIn(
                function Objekt(Objekt[] args...) { 
                    if(args.length != 1) 
                        return newError("wrong number of arguments. got=%d, want=1", args.length);
                    
                    if(args[0].type() != ObjectType.ARRAY) 
                        return newError("argument to `rest` must be ARRAY, got %s", args[0].type());

                    auto arr = cast(Array) args[0];
                    auto len = arr.elements.length;
                    if(len > 0) {
                        auto newElements = arr.elements[1 .. len].dup;
                        return new Array(newElements);
                    }

                    return NULL;
                }
            ),

        "push" : new BuiltIn(
                function Objekt(Objekt[] args...) { 
                    if(args.length != 2)
                        return newError("wrong number of arguments. got=%d, want=2", args.length);

                    if(args[0].type() != ObjectType.ARRAY)
                        return newError("argument to `push` must be ARRAY, got %s", args[0].type());

                    auto arr = cast(Array) args[0];
                    auto len = arr.elements.length;

                    auto newElements = arr.elements.dup;
                    newElements ~= args[1];

                    return new Array(newElements);
                    
                }
            ),
        "puts" : new BuiltIn(
                    function Objekt(Objekt[] args...) { 
                        foreach(arg; args) {
                            writeln(arg.inspect());
                        }

                        return NULL;
                    }
                ),
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