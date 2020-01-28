module objekt.objekt;

import std.string;
import std.array;
import std.conv;
import std.digest.murmurhash;

import ast.ast;
import objekt.environment;

/// 
enum ObjectType {
    INTEGER,
    BOOLEAN,
    NULL,
    RETURN_VALUE,
    ERROR,
    FUNCTION,
    STRING,
    BUILTIN,
    ARRAY,
}

alias BuiltInFunction = Objekt function(Objekt[] args...);

/+++/
interface Objekt {
    ObjectType type();  /// the type of the value
    string inspect();   /// introspection
}

/+++/
class Integer : Objekt {
    long value;     /// the value of the integer

    /+++/
    this(long value) {
        this.value = value;
    }

    /+++/
    ObjectType type() {
        return ObjectType.INTEGER;
    }

    /+++/
    string inspect() {
        return format("%d", this.value);
    }

    HashKey hashkey() {
        return HashKey(this.type(), to!size_t(this.value));
    }
}

/+++/
class String : Objekt {
    string value;

    /+++/
    this(string value) {
        this.value = value;
    }
    
    /+++/
    ObjectType type() {
        return ObjectType.STRING;
    }

    /+++/
    string inspect() {
        return this.value;
    }

    /+++/
    HashKey hashKey() {
        MurmurHash3!32 hasher;
        hasher.put(cast(ubyte[]) this.value);

        return HashKey(this.type(), to!size_t(hasher.get()));
    }
}

/+++/
class Boolean : Objekt {
    bool value; /// bool value

    /+++/
    this(bool value) {
        this.value = value;
    }

    /+++/
    ObjectType type() {
        return ObjectType.BOOLEAN;
    }

    /+++/
    string inspect() {
        return format("%s", this.value);
    }

    HashKey hashKey() {
        ulong value = this.value ? 1 : 0;
        return HashKey(this.type(), value);
    }
}

/***/
class Null : Objekt {
    
    /+++/
    ObjectType type() {
        return ObjectType.NULL;
    }

    /+++/
    string inspect() {
        return "null";
    }
}

/+++/
class ReturnValue : Objekt {
    Objekt value;   /// value to be returned

    /+++/
    this(Objekt value) {
        this.value = value;
    }

    /+++/
    ObjectType type() {
        return ObjectType.RETURN_VALUE;
    }

    /+++/
    string inspect() {
        return this.value.inspect();
    }
}

/+++/
class Err : Objekt {
    string message; /// error message

    /+++/
    this(string msg) {
        this.message = msg;
    }

    ///
    ObjectType type() {
        return ObjectType.ERROR;
    }

    ///
    string inspect() {
        return "ERROR: " ~ this.message;
    }
}

///
class Function : Objekt {
    Identifier[] parameters;  /// function parameters
    BlockStatement fnBody;  /// function body
    Environment env;        /// environment

    ///
    this(Identifier[] params, ref Environment env, BlockStatement fnBody) {
        this.parameters = params;
        this.env = env;
        this.fnBody = fnBody;
    }

    ///
    ObjectType type() {
        return ObjectType.FUNCTION;
    }

    ///
    string inspect() {
        string[] params;
        foreach (p; this.parameters) {
            params ~= p.asString(); 
        }

        string s = "fn(" ~ join(params, ", ") ~ ") {\n" ~ this.fnBody.asString() ~ "\n}";

        return s;
    }
}

/+++/
class BuiltIn : Objekt {
    BuiltInFunction fxn;

    /+++/
    this(BuiltInFunction fxn) {
        this.fxn = fxn;
    }

    /+++/
    ObjectType type() {
        return ObjectType.BUILTIN;
    }

    /+++/
    string inspect() {
        return "builtin function";
    }
}

/+++/
class Array : Objekt {
    Objekt[] elements;

    /+++/
    this(Objekt[] elements) {
        this.elements = elements;
    }

    /+++/
    ObjectType type() {
        return ObjectType.ARRAY;
    }

    /+++/
    string inspect() {
        string[] elements;
        foreach(elem; this.elements) {
            elements ~= elem.inspect();
        }

        string s = "[" ~ join(elements, ", ") ~ "]";

        return s;
    }
}