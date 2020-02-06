module compiler.symbol_table_test;

import std.stdio;

import compiler.symbol_table;


unittest {
    testDefine();
    testResolveGlobal();
}

///
void testDefine() {
    auto expected = [
        "a" : Symbol("a", SymbolScope.GLOBAL, 0),
        "b" : Symbol("b", SymbolScope.GLOBAL, 1),
    ];

    auto global = SymbolTable();

    auto a = global.define("a");
    if(a != expected["a"]) {
        stderr.writefln("expected a=%s, got=%s", expected["a"], a);
        assert(a == expected["a"]);
    }

    auto b = global.define("b");
    if(b != expected["b"]) {
        stderr.writefln("expected b=%s, got=%s", expected["b"], b);
        assert(b == expected["b"]);
    }
}

///
void testResolveGlobal() {
    auto global = SymbolTable();
    global.define("a");
    global.define("b");

    auto expected = [
        Symbol("a", SymbolScope.GLOBAL, 0),
        Symbol("b", SymbolScope.GLOBAL, 1)
    ];

    foreach(sym; expected) {
        auto result = global.resolve(sym.name);
        if(result.isNull) {
            stderr.writefln("name %s not resolvable", sym.name);
            continue;
        }

        if(result != sym) {
            stderr.writefln("expected %s to resolve to %s, got=%s",
                                sym.name, sym, result);
            assert(result == sym);
        }
    }
}