module objekt.objekt;

import std.stdio;
import std.string;
import std.array;
import std.conv;
import std.digest.crc;

import ast.ast;
import code.code;
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
    HASH,
    COMPILED_FUNCTION,
}

alias BuiltInFunction = Objekt function(Objekt[] args...);

/+++/
interface Objekt {
    /// the type of the value
    ObjectType type();  

    /// introspection
    string inspect();   
}

/+++/
interface Hashable {
    /+++/
    HashKey hashKey();
}

/+++/
class CompiledFunction : Objekt {
    Instructions instructions;      /// compiled instructions

    /+++/
    ObjectType type() {
        return ObjectType.COMPILED_FUNCTION;
    }

    /+++/
    string inspect() {
        return format("CompiledFunction[%s]", this);
    }
}

/+++/
class Hash : Objekt {
    HashPair[HashKey] pairs;    /// pairs

    ///
    this(HashPair[HashKey] pairs) {
        this.pairs = pairs;
    }

    /+++/
    ObjectType type() {
        return ObjectType.HASH;
    }

    /+++/
    string inspect() {
        string[] prs;
        foreach(key, pair; this.pairs) {
            prs ~= format("%s: %s", pair.key.inspect(), pair.value.inspect());
        }

        string s = "{" ~ join(prs, ", ") ~ "}";

        return s;
    }
}

/+++/
class Integer : Objekt, Hashable {
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
    
    /+++/
    HashKey hashKey() {
        return HashKey(this.type(), to!size_t(this.value));
    }
}

/+++/
class String : Objekt, Hashable {
    string value;   /// value

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
        return HashKey(this.type(), to!size_t(readUint32(crc32Of(this.value))));
    }
}

/+++/
class Boolean : Objekt, Hashable {
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

    /+++/
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
    BuiltInFunction fxn;    /// function

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
    Objekt[] elements;  /// array elements

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
        string[] elems;
        foreach(elem; this.elements) {
            elems ~= elem.inspect();
        }

        string s = "[" ~ join(elems, ", ") ~ "]";

        return s;
    }
}

/+++/
struct HashKey {
    ObjectType type;    /// type
    size_t value;       /// value
}

/+++/
struct HashPair {
    Objekt key;     /// key
    Objekt value;   /// value
}

///
uint readUint32(const ubyte[] data) 
{
	return data[0] << 24 |
	       data[1] << 16 |
		   data[2] << 8  |
		   data[3];
}