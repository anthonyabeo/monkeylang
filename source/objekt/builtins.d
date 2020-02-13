module objekt.builtins;

import std.conv;
import std.stdio;
import std.string;
import std.typecons;

import objekt.objekt;

alias BINS = Tuple!(string, "name", BuiltIn, "builtin");

auto builtins = [
    BINS(
        "len", 
        new BuiltIn(
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
        )
    ),
    BINS("
        puts", 
        new BuiltIn(
            function Objekt(Objekt[] args...) { 
                foreach(arg; args) {
                    writeln(arg.inspect());
                }

                return null;
            }
        )
    ),
    BINS(
        "first",
        new BuiltIn(
            function Objekt(Objekt[] args...) { 
                if(args.length != 1) 
                    return newError("wrong number of arguments. got=%d, want=1", args.length);

                if(args[0].type() != ObjectType.ARRAY) 
                    return newError("argument to `first` must be ARRAY, got %s", args[0].type());

                auto arr = cast(Array) args[0];
                if(arr.elements.length > 0)
                    return arr.elements[0];

                return null;
            }
        )
    ),
    BINS(
        "last",
        new BuiltIn(
            function Objekt(Objekt[] args...) { 
                if(args.length != 1) 
                    return newError("wrong number of arguments. got=%d, want=1", args.length);

                if(args[0].type() != ObjectType.ARRAY) 
                    return newError("argument to `last` must be ARRAY, got %s", args[0].type());

                auto arr = cast(Array) args[0];
                auto len = arr.elements.length;
                if(len > 0)
                    return arr.elements[len-1];
                
                return null;
            }
        ),
    ),
    BINS(
        "rest",
        new BuiltIn(
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

                return null;
            }
        )
    ),
    BINS(
        "push",
        new BuiltIn(
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
        )
    ),
];

///
Err newError(T...) (string fmt, T args) {
    return new Err(format(fmt, args));
}

///
BuiltIn getBuiltinByName(string name) {
    foreach(def; builtins) {
        if (def.name == name)
            return def.builtin;
    }

    return null;
}