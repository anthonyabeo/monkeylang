module vm.vm;

import std.string;

import code.code;
import objekt.objekt;
import compiler.compiler;

const size_t StackSize = 2048;   /// stack size

///
struct VM {
    Objekt[] constants;             /// constants pool
    Instructions instructions;      /// instructions

    Objekt[] stack;      /// stack
    size_t  sp;         /// stack pointer

    ///
    this(this) {
        this.stack = stack.dup;
    }

    /++++++++++++++++++++++++++++++
     + Constructor
     + Params:
     +     bytecode = 
     +++++++++++++++++++++++++++++/
    this(Bytecode bytecode) {
        this.instructions = bytecode.instructions;
        this.constants = bytecode.constants;

        this.stack = new Objekt[StackSize];

        this.sp = 0;
    }

    ///
    Objekt lastPoppedStackElem() {
        return this.stack[this.sp];
    }

    ///
    Objekt stackTop() {
        if(this.sp == 0)
            return null;

        return this.stack[this.sp - 1];
    }

    ///
    Error run() {
        for(size_t ip = 0; ip < this.instructions.length; ++ip) {
            auto op = cast(OPCODE) this.instructions[ip];
            final switch(op) {
                case OPCODE.OpConstant:
                    auto constIndex = readUint16(this.instructions[ip+1 .. $]);
                    ip += 2;

                    auto err = this.push(this.constants[constIndex]);
                    if(err !is null)
                        return err;

                    break;
                
                case OPCODE.OpAdd, OPCODE.OpSub, OPCODE.OpMul, OPCODE.OpDiv:
                    auto err = this.executeBinaryOperation(op);
                    if(err !is null)
                        return err;

                    break;
                    
                case OPCODE.OpPop:
                    this.pop();
                    break;
            }
        }

        return null;
    }

    ///
    Error executeBinaryOperation(OPCODE op) {
        auto right = this.pop();
        auto left = this.pop();

        auto leftType = left.type();
        auto rightType = right.type();

        if(leftType == ObjectType.INTEGER && rightType == ObjectType.INTEGER) {
            return this.executeBinaryIntegerOperation(op, left, right);
        }

        return new Error(format("unsupported types for binary operation: %s %s",
                            leftType, rightType));
    }

    ///
    Error executeBinaryIntegerOperation(OPCODE op, Objekt left, Objekt right) {
        auto leftValue = (cast(Integer) left).value;
        auto rightValue = (cast(Integer) right).value;

        long result;
        switch(op) {
            case OPCODE.OpAdd:
                result = leftValue + rightValue;
                break;
            case OPCODE.OpMul:
                result = leftValue * rightValue;
                break;
            case OPCODE.OpSub:
                result = leftValue - rightValue;
                break;
            case OPCODE.OpDiv:
                result = leftValue / rightValue;
                break;
            default:
                return new Error(format("unknown integer operator: %d", op));
        }

        return this.push(new Integer(result));
    }

    ///
    Error push(Objekt obj) {
        if(this.sp >= StackSize)
            return new Error(format("stackoverflow"));

        this.stack[this.sp] = obj;
        this.sp++;

        return null;
    }

    ///
    Objekt pop() {
        auto obj = this.stack[this.sp - 1];
        this.sp--;

        return obj;
    }
}