module objekt.environment;

import objekt.objekt;

///
struct Environment {
    Objekt[string] store;   /// store

    ///
    this(Objekt[string] store) {
        this.store = store;
    }

    ///
    Objekt get(string name) {
        if(name in this.store)
            return this.store[name];

        return null;
    }

    ///
    Objekt set(string name, Objekt val) {
        this.store[name] = val;
        return val;
    }
}