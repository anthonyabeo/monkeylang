module repl.repl;

import std.stdio;
import std.conv;

import token.token;
import lexer.lexer;

/// prompt for the interpreter console
enum PROMPT = ">>> ";

/// reading and executing command
void start() {
    Lexer* lexer;

    while(true) {
        write(PROMPT);
        foreach(line; stdin.byLine()) {
            lexer = new Lexer(to!string(line));

            for(auto tok = lexer.nextToken(); tok.type != TokenType.EOF; 
                tok = lexer.nextToken()) 
            {
                writefln("%s", tok);
            }
            break;
        }
    }
}