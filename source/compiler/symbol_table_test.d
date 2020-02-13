module compiler.symbol_table_test;

import std.stdio;
import std.typecons;

import compiler.symbol_table;


unittest {
    testDefine();
    testResolveGlobal();
    testResolveLocal();
    testResolveNestedLocal();
    testDefineResolveBuiltins();
    testResolveUnresolvableFree();
    testResolveFree();
}

///
void testDefine() {
    auto expected = [
        "a" : Symbol("a", SymbolScope.GLOBAL, 0),
        "b" : Symbol("b", SymbolScope.GLOBAL, 1),
        "c": Symbol("c", SymbolScope.LOCAL, 0),
        "d": Symbol("d", SymbolScope.LOCAL, 1),
        "e": Symbol("e", SymbolScope.LOCAL, 0),
        "f": Symbol("f", SymbolScope.LOCAL, 1),
    ];

    auto global = new SymbolTable(null);

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

    auto firstLocal = new SymbolTable(global);

    auto c = firstLocal.define("c");
    if(c != expected["c"]) {
        stderr.writefln("expected c=%s, got=%s", expected["c"], c);
        assert(c == expected["c"]);
    }

    auto d = firstLocal.define("d");
    if(d != expected["d"]) {
        stderr.writefln("expected d=%s, got=%s", expected["d"], d);
        assert(d == expected["d"]);
    }

    auto secondLocal = new SymbolTable(firstLocal);

    auto e = secondLocal.define("e");
    if (e != expected["e"]) {
        stderr.writefln("expected e=%s, got=%s", expected["e"], e);
        assert(e == expected["e"]);
    }

    auto f = secondLocal.define("f");
    if (f != expected["f"]) {
        stderr.writefln("expected f=%s, got=%s", expected["f"], f);
        assert(f == expected["f"]);
    }
}

///
void testResolveGlobal() {
    auto global = new SymbolTable(null);
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

///
void testResolveLocal() {
    auto global = new SymbolTable(null);
    global.define("a");
    global.define("b");

    auto firstLocal = new SymbolTable(global);
    firstLocal.define("c");
    firstLocal.define("d");

    auto secondLocal = new SymbolTable(firstLocal);
    secondLocal.define("e");
    secondLocal.define("f");

    alias SymS = Tuple!(SymbolTable, "table", Symbol[], "expectedSymbols");
    auto tests = [
        SymS(firstLocal, [
            Symbol("a", SymbolScope.GLOBAL, 0),
            Symbol("b", SymbolScope.GLOBAL, 1),
            Symbol("c", SymbolScope.LOCAL, 0),
            Symbol("d", SymbolScope.LOCAL, 1),
        ]),
        SymS(secondLocal, [
            Symbol("a", SymbolScope.GLOBAL, 0),
            Symbol("b", SymbolScope.GLOBAL, 1),
            Symbol("e", SymbolScope.LOCAL, 0),
            Symbol("f", SymbolScope.LOCAL, 1),
        ]),
    ];

    foreach(tt; tests) {
        foreach(sym; tt.expectedSymbols){
            auto result = tt.table.resolve(sym.name);
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
}

///
void testResolveNestedLocal() {
    auto global = new SymbolTable(null);
    global.define("a");
    global.define("b");

    auto firstLocal = new SymbolTable(global);
    firstLocal.define("c");
    firstLocal.define("d");

    auto secondLocal = new SymbolTable(firstLocal);
    secondLocal.define("e");
    secondLocal.define("f");

    alias SymS = Tuple!(SymbolTable, "table", Symbol[], "expectedSymbols");
    auto tests = [
        SymS(firstLocal, [
            Symbol("a", SymbolScope.GLOBAL, 0),
            Symbol("b", SymbolScope.GLOBAL, 1),
            Symbol("c", SymbolScope.LOCAL, 0),
            Symbol("d", SymbolScope.LOCAL, 1),
        ]),
        SymS(secondLocal, [
            Symbol("a", SymbolScope.GLOBAL, 0),
            Symbol("b", SymbolScope.GLOBAL, 1),
            Symbol("e", SymbolScope.LOCAL, 0),
            Symbol("f", SymbolScope.LOCAL, 1),
        ])
    ];

    foreach(tt; tests) {
        foreach(sym; tt.expectedSymbols) {
            auto result = tt.table.resolve(sym.name);
            if(result.isNull) {
                stderr.writefln("name %s not resolvable", sym.name);
                continue;
            }

            if(result != sym) {
                stderr.writefln("expected %s to resolve to %s, got=%s", sym.name, sym, result);
                assert(result == sym);
            }
        }
    }
}

///
void testDefineResolveBuiltins() {
    auto global = new SymbolTable(null);
    auto firstLocal = new SymbolTable(global);
    auto secondLocal = new SymbolTable(firstLocal);

    auto expected = [
        Symbol("a", SymbolScope.BUILTIN, 0),
        Symbol("c", SymbolScope.BUILTIN, 1),
        Symbol("e", SymbolScope.BUILTIN, 2),
        Symbol("f", SymbolScope.BUILTIN, 3),
    ];

    foreach(i, v; expected) {
        global.defineBuiltin(i, v.name);
    }

    foreach (table; [global, firstLocal, secondLocal]) {
        foreach (sym; expected) {
            const result = table.resolve(sym.name);
            if(result.isNull) {
                stderr.writefln("name %s not resolvable", sym.name);
                continue;
            }

            if(result != sym) {
                stderr.writefln("expected %s to resolve to %s, got=%s", sym.name, sym, result);
                assert(result == sym);
            }
        }
    }
}

///
void testResolveFree() {
    auto global = new SymbolTable(null);
    global.define("a");
    global.define("b");

    auto firstLocal = new SymbolTable(global);
    firstLocal.define("c");
    firstLocal.define("d");

    auto secondLocal = new SymbolTable(firstLocal);
    secondLocal.define("e");
    secondLocal.define("f");

    alias NewS = Tuple!(SymbolTable, "table", 
                        Symbol[], "expectedSymbols",
                        Symbol[], "expectedFreeSymbols");

    // Symbol[] s = [];
    auto tests = [
        NewS(
            firstLocal, 
            [
                Symbol("a", SymbolScope.GLOBAL, 0),
                Symbol("b", SymbolScope.GLOBAL, 1),
                Symbol("c", SymbolScope.LOCAL, 0),
                Symbol("d", SymbolScope.LOCAL, 1),
            ],
            [],
        ),
        NewS(
            secondLocal, 
            [
                Symbol("a", SymbolScope.GLOBAL, 0),
                Symbol("b", SymbolScope.GLOBAL, 1),
                Symbol("c", SymbolScope.FREE, 0),
                Symbol("d", SymbolScope.FREE, 1),
                Symbol("e", SymbolScope.LOCAL, 0),
                Symbol("f", SymbolScope.LOCAL, 1),
            ],
            [
                Symbol("c", SymbolScope.LOCAL, 0),
                Symbol("d", SymbolScope.LOCAL, 1),
            ]
        ),
    ];

    foreach (tt; tests) {
        foreach(sym; tt.expectedSymbols) {
            immutable result = tt.table.resolve(sym.name);
            if(result.isNull) {
                stderr.writefln("name %s not resolvable", sym.name);
                continue;
            }

            if (result != sym) {
                stderr.writefln("expected %s to resolve to %s, got=%s", sym.name, sym, result);
                assert(result == sym);
            }
        }

        if(tt.table.freeSymbols.length != tt.expectedFreeSymbols.length) {
            stderr.writefln("wrong number of free symbols. got=%d, want=%d",
                        tt.table.freeSymbols.length, tt.expectedFreeSymbols.length);
            continue;
        }

        foreach(i, sym; tt.expectedFreeSymbols) {
            const result = tt.table.freeSymbols[i];
            if (result != sym) {
                stderr.writefln("wrong free symbol. got=%s, want=%s", result, sym);
                assert(result == sym);
            }
        }
    }
}

///
void testResolveUnresolvableFree() {
    auto global = new SymbolTable(null);
    global.define("a");

    auto firstLocal = new SymbolTable(global);
    firstLocal.define("c");

    auto secondLocal = new SymbolTable(firstLocal);
    secondLocal.define("e");
    secondLocal.define("f");

    auto expected = [
        Symbol("a", SymbolScope.GLOBAL, 0),
        Symbol("c", SymbolScope.FREE, 0),
        Symbol("e", SymbolScope.LOCAL, 0),
        Symbol("f", SymbolScope.LOCAL, 1),
    ];

    foreach(sym; expected) {
        const result = secondLocal.resolve(sym.name);
        if (result.isNull) {
            stderr.writefln("name %s not resolvable", sym.name);
            continue;
        }

        if (result != sym) {
            stderr.writefln("expected %s to resolve to %+v, got=%+v", sym.name, sym, result);
            assert(result !is sym);
        }
    }

    const expectedUnresolvable = ["b", "d"];

    foreach(name; expectedUnresolvable) {
        const _ = secondLocal.resolve(name);
        if (!_.isNull) {
            stderr.writefln("name %s resolved, but was expected not to", name);
            assert(!_.isNull);
        }
    }
}
