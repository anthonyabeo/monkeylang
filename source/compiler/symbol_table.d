module compiler.symbol_table;

import std.typecons;


///
enum SymbolScope {
    GLOBAL,
    LOCAL,
}

///
struct Symbol {
    string name;            /// name
    SymbolScope skope;      /// scope
    size_t index;           /// index
}

///
class SymbolTable {
    SymbolTable outer;
    Symbol[string] store;   /// store
    size_t numDefinitions;  /// number of definitions
    
    this(SymbolTable symTab) {
        this.outer = symTab;
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
        Symbol symbol;
        symbol.name = name;
        symbol.index = this.numDefinitions;

        if(this.outer is null)
            symbol.skope = SymbolScope.GLOBAL;
        else    
            symbol.skope = SymbolScope.LOCAL;

        this.store[name] = symbol;
        this.numDefinitions++;

        return symbol;
    }

    ///
    Nullable!Symbol resolve(string name) {
        if((name !in this.store) && this.outer !is null)
            return this.outer.resolve(name);
        else if((name !in this.store) && this.outer is null)
            return Nullable!Symbol();

        return Nullable!Symbol(this.store[name]);
    }
}