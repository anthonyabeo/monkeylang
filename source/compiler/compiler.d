module compiler.compiler;

import std.stdio;
import std.conv;
import std.string;

import ast.ast;
import code.code;
import objekt.objekt;


/++
 + Compiler
 +/
struct Compiler {
    Instructions instructions;  /// instructions
    Objekt[] constants;         /// constants

    this(this) {
        this.constants = constants.dup;
    }
    
    /++++++++++++++++++++++++++++
     + Params:
     +    node =
     ++++++++++++++++++++++++++++/
    Error compile(Node node) {
        auto nde = to!string(typeid((cast(Object)node)));
        switch(nde) {
            case "ast.ast.Program":
                auto n = cast(Program) node;
                foreach(s; n.statements) {
                    auto err = this.compile(s);
                    if(err !is null)
                        return err;
                }

                break;
            case "ast.ast.ExpressionStatement":
                auto n = cast(ExpressionStatement) node;
                auto err = this.compile(n.expression);
                if(err !is null)
                    return err;

                this.emit(OPCODE.OpPop);

                break;
            
            case "ast.ast.InfixExpression":
                auto n = cast(InfixExpression) node;

                if(n.operator == "<") {
                    auto err = this.compile(n.right);
                    if(err !is null)
                        return err;

                    err = this.compile(n.left);
                    if(err !is null)
                        return err;

                    this.emit(OPCODE.OpGreaterThan);
                    
                    return null;
                }

                auto err = this.compile(n.left);
                if(err !is null)
                    return err;
                
                err = this.compile(n.right);
                if(err !is null)
                    return err;

                switch(n.operator) {
                    case "+":
                        this.emit(OPCODE.OpAdd);
                        break;
                    case "-":
                        this.emit(OPCODE.OpSub);
                        break;
                    case "*":
                        this.emit(OPCODE.OpMul);
                        break;
                    case "/":
                        this.emit(OPCODE.OpDiv);
                        break;
                    case ">":
                        this.emit(OPCODE.OpGreaterThan);
                        break;
                    case "==":
                        this.emit(OPCODE.OpEqual);
                        break;
                    case "!=":
                        this.emit(OPCODE.OpNotEqual);
                        break;
                    default:
                        return new Error(format("unknown operator %s", n.operator));
                }
                break;
            
            case "ast.ast.IntegerLiteral":
                auto n = cast(IntegerLiteral) node;
                auto integer = new Integer(n.value);
                this.emit(OPCODE.OpConstant, this.addConstant(integer));

                break;

            case "ast.ast.BooleanLiteral":
                auto n = cast(BooleanLiteral) node;
                if(n.value) 
                    this.emit(OPCODE.OpTrue);
                else
                    this.emit(OPCODE.OpFalse);
                    
                break;
            default:
                break;
        }

        return null;
    }

    /+++/
    Bytecode bytecode() {
        return Bytecode(this.instructions, this.constants);
    }

    ///
    size_t addConstant(Objekt obj) {
        this.constants ~= obj;
        return this.constants.length - 1;
    }

    ///
    size_t emit(Opcode op, size_t[] operands...) {
        auto ins = make(op, operands);
        auto pos = this.addInstruction(ins);

        return pos;
    }

    ///
    size_t addInstruction(ubyte[] ins) {
        auto posNewInstruction = this.instructions.length;
        this.instructions ~= ins;

        return posNewInstruction;
    }
}

/++++++++++++++++++++++++++++++
 + BYTECODE
 +++++++++++++++++++++++++++++/
 struct Bytecode {
    Instructions instructions;  /// instructions
    Objekt[] constants;         /// constants

    this(this) {
        this.constants = constants.dup;
    }
 }