module repl.repl;

import std.stdio;
import std.conv;
import std.file;
import std.string;

import token.token;
import lexer.lexer : Lexer;
import parser.parser : Parser;
import ast.ast : Program;
import evaluator.eval;
import objekt.objekt;
import objekt.environment;
import compiler.compiler;
import vm.vm;
import compiler.symbol_table;

/// monkey face
const MONKEY_FACE = 
                    `    __,__
                   .--. .-" "-. .--.
                 / ..\/ .-. .-. \/ ..\
                |   | '| / Y \ |' |   |
                |  \ \ \ 0 | 0 / / /  |
                 \ '-,\.-""""""-./,-'/
                  ''-' /_ ^ ^ _\ '-''
                      | \._ _./ |
                      \ \ '~' / /
                     '._ '-=-' _.'
                        '-----' 
            `;

/// prompt for the interpreter console
enum PROMPT = ">>> ";

/// reading and executing command
void start() {
    Lexer lexer;
    Parser parser;
    Program program;

    Objekt[] constants;        
    Objekt[] globals = new Objekt[GLOBALS_SIZE];
    auto symTable = SymbolTable();
    auto skope = CompilationScope();
    auto compiler = Compiler(symTable, constants, skope);

    auto env = new Environment();

    string line;

    while(true) {
        write(PROMPT);
        line = strip(readln());

        lexer = Lexer(line);
        parser = Parser(lexer);
        program = parser.parseProgram();

        if(parser.errs.length != 0) {
            printParserErrors(parser.errs);
            continue;
        }

        auto err = compiler.compile(program);
        if(err !is null) {
            writefln("Woops! Compilation failed:\n %s\n", err.msg);
            continue;
        }

        auto code = compiler.bytecode();
        constants = code.constants;

        auto machine = VM(code, globals);
        err = machine.run();
        if(err !is null) {
            writefln("Woops! Executing bytecode failed:\n %s\n", err);
            continue;
        }

        auto lastPopped = machine.lastPoppedStackElem();
        if(lastPopped.type() != ObjectType.NULL)
            writefln("%s", lastPopped.inspect());
    }
}

///
void printParserErrors(string[] errors) {
    writeln(MONKEY_FACE);
    writeln("Woops! We ran into some monkey business here!\nparser errors:");
    foreach(msg; errors) {
        stderr.writefln("\t%s", msg);
    }
}