module objekt.objekt;

import std.string;

/// 
enum ObjectType {
    INTEGER,
    BOOLEAN,
    NULL,
    RETURN_VALUE,
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