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

import repl.repl;

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

void main(string[] args)
{
	SysTime begin;
	Duration duration;
    Objekt result;

	if(args.length < 2) 
	{
		writeln("Hello! This is the Monkey programming language!");
		writeln("Feel free to type in commands");
		start();
	}
	else 
	{
		string engine;
    	getopt(args, "engine", &engine);

		Objekt[] constants = [];        
		Objekt[] globals = new Objekt[GLOBALS_SIZE];
		auto symTable = new SymbolTable(null);

		auto lex = Lexer(input);
		auto parser = Parser(lex);
		auto program = parser.parseProgram();
		
		if(engine == "vm") 
		{
			auto comp = Compiler(symTable, constants);
			auto err = comp.compile(program);
			if (err !is null) {
				writefln("compiler error: %s", err.msg);
				return;
			}

			auto code = comp.bytecode();
			auto machine = VM(code, globals);

			begin = Clock.currTime();
			err = machine.run();
			if (err !is null) {
				writefln("vm error: %s", err.msg);
				return;
			}

			duration = Clock.currTime() - begin;
			result = machine.lastPoppedStackElem();
		} 
		else 
		{
			auto env = new Environment();
			begin = Clock.currTime();
			result = eval(program, env);
			duration = Clock.currTime() - begin;
    	}

		writefln(
			"engine=%s, result=%s, duration=%s\n",
			engine,
			result.inspect(),
			duration
		);
	}
}
