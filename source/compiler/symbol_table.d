module compiler.symbol_table;

import std.typecons;


///
enum SymbolScope {
    GLOBAL,
    LOCAL,
    BUILTIN,
    FREE,
    FUNCTION,
}

///
struct Symbol {
    string name;            /// name
    SymbolScope skope;      /// scope
    size_t index;           /// index
}

///
class SymbolTable {
    SymbolTable outer;      /// outer
    Symbol[string] store;   /// store
    size_t numDefinitions;  /// number of definitions
    Symbol[] freeSymbols;   /// free symbols

    ///
    this(SymbolTable outer) {
        this.outer = outer;
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
        if((name !in this.store) && this.outer !is null) {
            auto obj = this.outer.resolve(name);
            if(obj.isNull)
                return obj;

            if (obj.skope == SymbolScope.GLOBAL || obj.skope == SymbolScope.BUILTIN)
                return obj;

            auto free = this.defineFree(obj);

            return Nullable!Symbol(free);
        }
        else if((name !in this.store) && this.outer is null)
            return Nullable!Symbol();

        return Nullable!Symbol(this.store[name]);
    }

    ///
    Symbol defineBuiltin(size_t index, string name) {
        auto symbol = Symbol(name, SymbolScope.BUILTIN, index);
        this.store[name] = symbol;

        return symbol;
    }

    ///
    Symbol defineFree(ref Symbol original) {
        this.freeSymbols ~= original;

        const symbol = Symbol(original.name, SymbolScope.FREE, this.freeSymbols.length - 1);
        this.store[original.name] = symbol;

        return symbol;
    }

    ///
    Symbol defineFunctionName(string name)  {
        auto symbol = Symbol(name, SymbolScope.FUNCTION, 0);
        this.store[name] = symbol;

        return symbol;
    }
}