module objekt.objekt;

import std.string;
import std.array;

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
}

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