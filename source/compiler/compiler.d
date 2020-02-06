module compiler.compiler;

import std.stdio;
import std.conv;
import std.string;

import ast.ast;
import code.code;
import objekt.objekt;
import compiler.symbol_table;

/++
 + Compiler
 +/
struct Compiler {
    Instructions instructions;               /// instructions
    Objekt[] constants;                      /// constants
    EmittedInstruction lastInstruction;      /// last instruction
    EmittedInstruction previousInstruction;  /// previous instruction
    SymbolTable symTable;                    /// symbol table

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
            
            case "ast.ast.PrefixExpression":
                auto n = cast(PrefixExpression) node;
                auto err = this.compile(n.right);
                if(err !is null)
                    return err; 

                switch(n.operator) {
                    case "!":
                        this.emit(OPCODE.OpBang);
                        break;
                    case "-":
                        this.emit(OPCODE.OpMinus);
                        break;
                    default:
                        return new Error(format("unknown operator %s", n.operator));
                }

                break;

            case "ast.ast.IfExpression":
                auto n = cast(IfExpression) node;
                auto err = this.compile(n.condition);
                if(err !is null)
                    return err; 

                auto jumpNotTruthyPos = this.emit(OPCODE.OpJumpNotTruthy, 9999);

                err = this.compile(n.consequence);
                if(err !is null)
                    return err; 

                if(this.lastInstructionIsPop())
                    this.removeLastPop();

                auto jumpPos = this.emit(OPCODE.OpJump, 9999);

                auto afterConsequencePos = this.instructions.length;
                this.changeOperand(jumpNotTruthyPos, afterConsequencePos);

                if(n.alternative is null) {
                    this.emit(OPCODE.OpNull);
                } else {
                    err = this.compile(n.alternative);
                    if(err !is null)
                        return err;
                    
                    if(this.lastInstructionIsPop())
                        this.removeLastPop();
                }

                auto afterAlternativePos = this.instructions.length;
                this.changeOperand(jumpPos, afterAlternativePos);

                break;

            case "ast.ast.BlockStatement":
                auto n = cast(BlockStatement) node;
                foreach(s; n.statements) {
                    auto err = this.compile(s);
                    if(err !is null)
                        return err; 
                }

                break;
            
            case "ast.ast.LetStatement":
                auto n = cast(LetStatement) node;
                auto err = this.compile(n.value);
                if(err !is null)
                    return err; 

                auto symbol = this.symTable.define(n.name.value);
                this.emit(OPCODE.OpSetGlobal, symbol.index);

                break;
            case "ast.ast.Identifier":
                auto n = cast(Identifier) node;
                auto symbol = this.symTable.resolve(n.value);
                if(symbol.isNull)
                    return new Error(format("undefined variable %s", n.value));
                
                this.emit(OPCODE.OpGetGlobal, symbol.index);
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

        this.setLastInstruction(cast(OPCODE) op, pos);

        return pos;
    }

    ///
    size_t addInstruction(ubyte[] ins) {
        auto posNewInstruction = this.instructions.length;
        this.instructions ~= ins;

        return posNewInstruction;
    }

    ///
    void setLastInstruction(OPCODE op, size_t pos) {
        auto prev = this.lastInstruction;
        auto last = EmittedInstruction(op, pos);

        this.previousInstruction = prev;
        this.lastInstruction = last;
    }

    ///
    bool lastInstructionIsPop() {
        return this.lastInstruction.opcode == OPCODE.OpPop;
    }

    ///
    void removeLastPop() {
        this.instructions = this.instructions[0 .. this.lastInstruction.pos];
        this.lastInstruction = this.previousInstruction;
    }

    ///
    void replaceInstruction(size_t pos, ubyte[] newInstruction) {
        for(size_t i = 0; i < newInstruction.length; ++i) {
            this.instructions[pos+i] = newInstruction[i];
        }
    }

    ///
    void changeOperand(size_t opPos, size_t operand) {
        auto op = cast(OPCODE) this.instructions[opPos];
        auto newInstruction = make(op, operand);

        this.replaceInstruction(opPos, newInstruction);
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

/++++++++++++++++++++++++++++++
 + EMITTED INSTRUCTION
 +++++++++++++++++++++++++++++/
 struct EmittedInstruction {
     OPCODE opcode;
     size_t pos;
 }