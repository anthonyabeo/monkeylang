module repl.repl;

import std.stdio;
import std.conv;
import std.file;

import token.token;
import lexer.lexer : Lexer;
import parser.parser : Parser;
import ast.ast : Program;


/// prompt for the interpreter console
enum PROMPT = ">>> ";

/// reading and executing command
void start() {
    Lexer lexer;
    Parser parser;
    Program program;

    while(true) {
        write(PROMPT);
        foreach(line; stdin.byLine()) {
            lexer = Lexer(to!string(line));
            parser = Parser(lexer);
            program = parser.parseProgram();

            if(parser.errs.length != 0) {
                printParserErrors(parser.errors());
                continue;
            }

            writefln("%s", program.asString());

            break;
        }
    }
}

///
void printParserErrors(string[] errors) {
    foreach(msg; errors) {
        stderr.writefln("\t", msg);
    }
}