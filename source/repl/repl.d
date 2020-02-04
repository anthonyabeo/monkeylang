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

        auto compiler = Compiler();
        auto err = compiler.compile(program);
        if(err !is null) {
            writefln("Woops! Compilation failed:\n %s\n", err.msg);
            continue;
        }

        auto machine = VM(compiler.bytecode());
        err = machine.run();
        if(err !is null) {
            writefln("Woops! Executing bytecode failed:\n %s\n", err);
            continue;
        }

        auto stackTop = machine.stackTop();
        if(stackTop.type() != ObjectType.NULL)
            writefln("%s", stackTop.inspect());
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