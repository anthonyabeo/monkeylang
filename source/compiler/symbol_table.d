module compiler.symbol_table;

import std.typecons;


///
enum SymbolScope {
    GLOBAL,
}

///
struct Symbol {
    string name;            /// name
    SymbolScope skope;      /// scope
    size_t index;           /// index
}

///
struct SymbolTable {
    Symbol[string] store;   /// store
    size_t numDefinitions;  /// number of definitions
    
    this(this) {
        this.store = store.dup;
    }

    /++
     + Define
     +
     + Params
     +      name=
     +
     + Return
     +      Symbol
     +/
    Symbol define(string name) {
        auto symbol = Symbol(name, SymbolScope.GLOBAL, this.numDefinitions);
        this.store[name] = symbol;
        this.numDefinitions++;

        return symbol;
    }

    ///
    Nullable!Symbol resolve(string name) {
        if(name !in this.store)
            return Nullable!Symbol();

        return Nullable!Symbol(this.store[name]);
    }
}