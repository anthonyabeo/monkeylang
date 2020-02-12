module compiler.compiler;

import std.stdio;
import std.conv;
import std.string;
import std.algorithm.sorting;

import ast.ast;
import code.code;
import objekt.objekt;
import compiler.symbol_table;

/++
 + Compiler
 +/
struct Compiler {
    Objekt[] constants;                      /// constants
    SymbolTable symTable;                    /// symbol table
    CompilationScope[] scopes;               /// scopes
    size_t scopeIndex;                       /// scope index

    /++++++++++++++++++++++++++++
     + Params:
     +    node =
     ++++++++++++++++++++++++++++/
    this(ref SymbolTable symTable, Objekt[] constants, ref CompilationScope skope) {
        this.symTable = symTable;
        this.constants = constants;
        this.scopes ~= CompilationScope();
        this.scopeIndex = 0;
    }

    this(this) {
        this.constants = constants.dup;
        this.scopes = scopes.dup;
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

                if(this.lastInstructionIs(OPCODE.OpPop))
                    this.removeLastPop();

                auto jumpPos = this.emit(OPCODE.OpJump, 9999);

                auto afterConsequencePos = this.currentInstructions().length;
                this.changeOperand(jumpNotTruthyPos, afterConsequencePos);

                if(n.alternative is null) {
                    this.emit(OPCODE.OpNull);
                } else {
                    err = this.compile(n.alternative);
                    if(err !is null)
                        return err;
                    
                    if(this.lastInstructionIs(OPCODE.OpPop))
                        this.removeLastPop();
                }

                auto afterAlternativePos = this.currentInstructions().length;
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
                if(symbol.skope == SymbolScope.GLOBAL)
                    this.emit(OPCODE.OpSetGlobal, symbol.index);
                else
                    this.emit(OPCODE.OpSetLocal, symbol.index);

                break;
            case "ast.ast.Identifier":
                auto n = cast(Identifier) node;
                auto symbol = this.symTable.resolve(n.value);
                if(symbol.isNull)
                    return new Error(format("undefined variable %s", n.value));
                
                if(symbol.skope == SymbolScope.GLOBAL)
                    this.emit(OPCODE.OpGetGlobal, symbol.index);
                else
                    this.emit(OPCODE.OpGetLocal, symbol.index);

                break;
            
            case "ast.ast.StringLiteral":
                auto n = cast(StringLiteral) node; 
                auto str = new String(n.value);
                this.emit(OPCODE.OpConstant, this.addConstant(str));
            
                break;
            case "ast.ast.ArrayLiteral":
                auto n = cast(ArrayLiteral) node;
                foreach(el; n.elements) {
                    auto err = this.compile(el);
                    if(err !is null)
                        return err;
                }

                this.emit(OPCODE.OpArray, n.elements.length);
                break;

            case "ast.ast.HashLiteral":
                auto n = cast(HashLiteral) node;

                Expression[] keys = n.pairs.keys;
                sort!((a, b) => a.asString() < b.asString()) (keys);
 
                foreach (k; keys) {
                    auto err = this.compile(k);
                    if(err !is null)
                        return err;

                    err = this.compile(n.pairs[k]);
                    if(err !is null)
                        return null;
                }

                this.emit(OPCODE.OpHash, (n.pairs.length * 2));

                break;
            case "ast.ast.IndexExpression":
                auto n = cast(IndexExpression) node;
                auto err = this.compile(n.left);
                if(err !is null)
                    return err;

                err = this.compile(n.index);
                if(err !is null)
                    return err;

                this.emit(OPCODE.OpIndex);

                break;

            case "ast.ast.FunctionLiteral":
                auto n = cast(FunctionLiteral) node;
                this.enterScope();

                auto err = this.compile(n.fnBody);
                if(err !is null)
                    return err;

                if(this.lastInstructionIs(OPCODE.OpPop))
                    this.replaceLastPopWithReturn();
                
                if(!this.lastInstructionIs(OPCODE.OpReturnValue))
                    this.emit(OPCODE.OpReturn);

                auto numLocals = this.symTable.numDefinitions;
                auto instructions = this.leaveScope();

                auto compiledFn = new CompiledFunction(instructions);
                compiledFn.numLocals = cast(int) numLocals;

                this.emit(OPCODE.OpConstant, this.addConstant(compiledFn));

                break;
            case "ast.ast.ReturnStatement":
                auto n = cast(ReturnStatement) node;

                auto err = this.compile(n.returnValue);
                if(err !is null)
                    return err;

                this.emit(OPCODE.OpReturnValue);
                
                break;
            case "ast.ast.CallExpression":
                auto n = cast(CallExpression) node;

                auto err = this.compile(n.fxn);
                if(err !is null)
                    return err;

                this.emit(OPCODE.OpCall);

                break;

            default:
                break;
        }

        return null;
    }
    /+++/
    void replaceLastPopWithReturn() {
        auto lastPos = this.scopes[this.scopeIndex].lastInstruction.pos;
        this.replaceInstruction(lastPos, make(OPCODE.OpReturnValue));
        this.scopes[this.scopeIndex].lastInstruction.opcode = OPCODE.OpReturnValue;
    }

    /+++/
    void enterScope() {
        auto scpe = CompilationScope();
        this.scopes ~= scpe;
        this.scopeIndex++;

        this.symTable = new SymbolTable(this.symTable);
    }

    /+++/
    Instructions leaveScope() {
        auto instructions = this.currentInstructions();

        this.scopes = this.scopes[0..$-1];
        this.scopeIndex--;

        this.symTable = this.symTable.outer;

        return instructions;
    }

    /+++/
    void replaceLastPopWithReturn() {
        auto lastPos = this.scopes[this.scopeIndex].lastInstruction.pos;
        this.replaceInstruction(lastPos, make(OPCODE.OpReturnValue));

        this.scopes[this.scopeIndex].lastInstruction.opcode = OPCODE.OpReturnValue;
    }

    /+++/
    Instructions currentInstructions() {
        return this.scopes[this.scopeIndex].instructions;
    }

    /+++/
    Bytecode bytecode() {
        return Bytecode(this.currentInstructions(), this.constants);
    }

    ///
    size_t addConstant(Objekt obj) {
        this.constants ~= obj;

        auto len = this.constants.length;
        return len - 1;
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
        auto posNewInstruction = this.currentInstructions().length;
        
        this.scopes[this.scopeIndex].instructions = this.currentInstructions() ~ ins;

        return posNewInstruction;
    }

    ///
    void setLastInstruction(OPCODE op, size_t pos) {
        immutable prev = this.scopes[this.scopeIndex].lastInstruction;
        immutable last = EmittedInstruction(op, pos);

        this.scopes[this.scopeIndex].previousInstruction = prev;
        this.scopes[this.scopeIndex].lastInstruction = last;
    }

    ///
    bool lastInstructionIs(OPCODE op) {
        if(this.currentInstructions().length == 0)
            return false;

        return this.scopes[this.scopeIndex].lastInstruction.opcode == op;
    }

    ///
    void removeLastPop() {
        auto last = this.scopes[this.scopeIndex].lastInstruction;
        auto previous = this.scopes[this.scopeIndex].previousInstruction;

        auto old = this.currentInstructions();
        auto knew = old[0..last.pos];

        this.scopes[this.scopeIndex].instructions = knew;
        this.scopes[this.scopeIndex].lastInstruction = previous;
    }

    ///
    void replaceInstruction(size_t pos, ubyte[] newInstruction) {
        auto ins = this.currentInstructions();

        for(size_t i = 0; i < newInstruction.length; ++i) {
            ins[pos+i] = newInstruction[i];
        }
    }

    ///
    void changeOperand(size_t opPos, size_t operand) {
        auto op = cast(OPCODE) this.currentInstructions()[opPos];
        auto newInstruction = make(op, operand);
        this.replaceInstruction(opPos, newInstruction);
    }

    ///
    void enterScope() {
        this.scopes ~= CompilationScope();
        this.scopeIndex++;

        this.symTable = new SymbolTable(this.symTable);
    }

    ///
    Instructions leaveScope() {
        auto instructions = this.currentInstructions();
        this.scopes = this.scopes[0..$-1];
        this.scopeIndex--;

        this.symTable = this.symTable.outer;

        return instructions;
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
     OPCODE opcode;         /// opcode
     size_t pos;            /// position
 }

 /++++++++++++++++++++++++++++++
 + COMPILATION SCOPE
 +++++++++++++++++++++++++++++/
 struct CompilationScope {
    Instructions instructions;              /// instructions
    EmittedInstruction lastInstruction;     /// last Instruction
    EmittedInstruction previousInstruction; /// prevoius instruction

    this(this) {
        this.instructions = instructions.dup;
    }
 }