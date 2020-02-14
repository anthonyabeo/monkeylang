import std.stdio;
import std.getopt;
import std.datetime.systime;

import core.time;

import compiler.compiler;
import evaluator.eval;
import lexer.lexer;
import objekt.objekt;
import parser.parser;
import vm.vm;
import compiler.symbol_table;
import objekt.environment;

static const input = `
    let fibonacci = fn(x) {
        if (x == 0) {
            0
        } else {
            if (x == 1) {
                return 1;
            } else {
                fibonacci(x - 1) + fibonacci(x - 2);
            }
        }
    };
    fibonacci(35);
`;

void main(string[] args) {
    Duration duration;
    Objekt result;

    string engine;
    getopt(args, "engine", &engine);

    Objekt[] constants = [];        
    Objekt[] globals = new Objekt[GLOBALS_SIZE];
    auto symTable = new SymbolTable(null);

    auto lex = Lexer(input);
    auto parser = Parser(lex);
    auto program = parser.parseProgram();
	
    if(engine == "vm") {
        auto comp = Compiler(symTable, constants);
        auto err = comp.compile(program);
        if (err !is null) {
            writefln("compiler error: %s", err.msg);
            return;
        }

        auto code = comp.bytecode();
        auto machine = VM(code, globals);

        auto start = Clock.currTime();
        err = machine.run();
        if (err !is null) {
            writefln("vm error: %s", err.msg);
            return;
        }

        duration = Clock.currTime() - start;
        result = machine.lastPoppedStackElem();
    } 
    else {
        auto env = new Environment();
        auto start = Clock.currTime();
        result = eval(program, env);
        duration = Clock.currTime() - start;
    }

    writefln(
        "engine=%s, result=%s, duration=%s\n",
        engine,
        result.inspect(),
        duration
    );
}