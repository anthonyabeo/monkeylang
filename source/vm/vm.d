module vm.vm;

import std.string;

import code.code;
import objekt.objekt;
import compiler.compiler;
import evaluator.builtins : TRUE, FALSE;


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
                
                case OPCODE.OpTrue:
                    auto err = this.push(TRUE);
                    if(err !is null)
                        return err;
                    
                    break;

                case OPCODE.OpFalse:
                    auto err = this.push(FALSE);
                    if(err !is null)
                        return err;

                    break;
                
                case OPCODE.OpEqual, OPCODE.OpNotEqual, OPCODE.OpGreaterThan:
                    auto err = this.executeComparison(op);
                    if(err !is null)
                        return err;

                    break;
                
                case OPCODE.OpMinus:
                    auto err = this.executeMinusOperator();
                    if(err !is null)
                        return err; 

                    break;

                case OPCODE.OpBang:
                    auto err = this.executeBangOperator();
                    if(err !is null)
                        return err;

                    break;
                
                case OPCODE.OpJumpNotTruthy:
                    immutable pos = readUint16(this.instructions[ip+1 .. $]);
                    ip += 2;

                    auto condition = this.pop();
                    if(!isTruthy(condition))
                        ip = pos - 1;

                    break;

                case OPCODE.OpJump:
                    immutable pos = readUint16(this.instructions[ip+1 .. $]);
                    ip = pos - 1;
                    break;
            }
        }

        return null;
    }

    ///
    Error executeMinusOperator() {
        auto operand = this.pop();
        if(operand.type() != ObjectType.INTEGER) {
            return new Error(format("unsupported type for negation: %s", 
                                        operand.type()));
        }

        auto value = (cast(Integer) operand).value;

        return this.push(new Integer(-value));
    }

    ///
    Error executeBangOperator() {
        auto operand = this.pop();
        if(operand.inspect() == TRUE.inspect()) return this.push(FALSE);
        else if(operand.inspect() == FALSE.inspect()) return this.push(TRUE);
        else return this.push(FALSE);
    }

    /// 
    Error executeComparison(OPCODE op) {
        auto right = this.pop();
        auto left = this.pop();

        if(left.type() == ObjectType.INTEGER || right.type() == ObjectType.INTEGER) {
            return this.executeIntegerComparison(op, left, right);
        }

        switch(op) {
            case OPCODE.OpEqual:
                return this.push(nativeBoolToBooleanObject(right == left));
            case OPCODE.OpNotEqual:
                return this.push(nativeBoolToBooleanObject(right != left));
            default:
                return new Error(format("unknown operator: %d (%s %s)",
                                    op, left.type(), right.type()));
        }
    }

    ///
    Error executeIntegerComparison(OPCODE op, Objekt left, Objekt right) {
        auto leftValue = (cast(Integer) left).value;
        auto rightValue = (cast(Integer) right).value;

        switch(op) {
            case OPCODE.OpEqual:
                return this.push(nativeBoolToBooleanObject(rightValue == leftValue));
            case OPCODE.OpNotEqual:
                return this.push(nativeBoolToBooleanObject(rightValue != leftValue));
            case OPCODE.OpGreaterThan:
                return this.push(nativeBoolToBooleanObject(leftValue > rightValue));
            default:
                return new Error(format("unknown operator: %d", op));

        }
    }

    ///
    Boolean nativeBoolToBooleanObject(bool input) {
        if(input) return TRUE;
        return FALSE;
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

///
bool isTruthy(Objekt obj) {
    if(obj.type() == ObjectType.BOOLEAN)
        return (cast(Boolean) obj).value;
    else
        return true;
}