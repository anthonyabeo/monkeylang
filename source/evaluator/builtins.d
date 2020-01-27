module evaluator.builtins;

import std.stdio;
import std.conv;

import objekt.objekt;
import evaluator.utils;

BuiltIn bin;
BuiltIn[string] builtins;

static this() {
    bin = new BuiltIn(
        function Objekt(Objekt[] args...) { 
            if(args.length != 1) 
                return newError("wrong number of arguments. got=%d, want=1", args.length);

            switch(args[0].type()) {
                case ObjectType.STRING:
                    auto arg = cast(String) args[0];
                    return new Integer(to!long(arg.value.length));
                default: 
                    return newError("argument to `len` not supported, got %s", args[0].type());
            }
        }
    );

    builtins = ["len" : bin];
}
