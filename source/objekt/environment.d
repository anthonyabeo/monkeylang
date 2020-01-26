module objekt.environment;

import objekt.objekt;

///
class Environment {
    Objekt[string] store;   /// store
    Environment outer;      /// enclosing scope environment

    ///
    this() {
        this.store = (Objekt[string]).init;
    }

    ///
    static newEnclosingEnvironment(Environment outer) {
        auto env = new Environment();
        env.outer = outer;

        return env;
    }

    ///
    Objekt get(string name) {
        Objekt obj = this.store.get(name, null);

        if(obj is null && (this.outer !is null))
            obj = this.outer.get(name);
        
        return obj;
    }

    ///
    Objekt set(string name, Objekt val) {
        this.store[name] = val;
        return val;
    }
}