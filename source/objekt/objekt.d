module objekt.objekt;

import std.string;

/// 
enum ObjectType {
    INTEGER,
    BOOLEAN,
    NULL,
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