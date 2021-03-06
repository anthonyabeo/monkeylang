module vm.vm;

import std.string;
import std.typecons;
import std.conv;
import std.stdio;

import vm.frame;
import code.code;
import vm.frame;
import objekt.objekt;
import objekt.builtins;
import compiler.compiler;
import evaluator.builtins : TRUE, FALSE, NULL;


const size_t STACK_SIZE = 2048;       /// stack size
const size_t GLOBALS_SIZE = 65_536;   /// globals size
const size_t MAX_FRAMES = 1024;       /// frames size


///
struct VM {
    Objekt[] constants;             /// constants pool

    Objekt[] stack;      /// stack
    size_t  sp;         /// stack pointer

    Objekt[] globals;   /// globals

    Frame[] frames;     /// frames
    size_t framesIndex;   /// frame index

    ///
    this(this) {
        this.stack = stack.dup;
        this.globals = globals.dup;
        this.constants = constants.dup;
        this.frames = frames.dup;
    }

    /++++++++++++++++++++++++++++++
     + Constructor
     + Params:
     +     bytecode = 
     +++++++++++++++++++++++++++++/
    this(ref Bytecode bytecode, Objekt[] globals) {
        auto mainFn = new CompiledFunction(bytecode.instructions);
        auto mainClosure = new Closure(mainFn);
        auto mainFrame = new Frame(mainClosure, 0);

        this.frames = new Frame[MAX_FRAMES];
        this.frames[0] = mainFrame;
        this.framesIndex = 1;

        this.constants = bytecode.constants;

        this.stack = new Objekt[STACK_SIZE];
        this.globals = globals;

        this.sp = 0;
    }

    ///
    Frame currentFrame() {
        return this.frames[this.framesIndex-1];
    }

    ///
    void pushFrame(Frame f) {
        this.frames[this.framesIndex] = f;
        this.framesIndex++;
    }

    ///
    Frame popFrame() {
        this.framesIndex--;
        return this.frames[this.framesIndex];
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
        int ip;
        Instructions ins;
        OPCODE op;  

        while(this.currentFrame().ip < (cast(int) this.currentFrame().instructions().length - 1))
        {            
            this.currentFrame().ip += 1;
            
            ip = this.currentFrame().ip;
            ins = this.currentFrame().instructions(); 
            op = cast(OPCODE) ins[ip];

            final switch(op) {
                case OPCODE.OpConstant:
                    auto constIndex = readUint16(ins[ip+1 .. $]);
                    this.currentFrame().ip += 2;

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
                    immutable pos = readUint16(ins[ip+1 .. $]);
                    this.currentFrame().ip += 2;

                    auto condition = this.pop();
                    if(!isTruthy(condition))
                        this.currentFrame().ip = pos - 1;

                    break;

                case OPCODE.OpJump:
                    immutable pos = readUint16(ins[ip+1 .. $]);
                    this.currentFrame().ip = pos - 1;

                    break;
                
                case OPCODE.OpNull:
                    auto err = this.push(NULL);
                    if(err !is null)
                        return err;
                    
                    break;

                case OPCODE.OpGetGlobal:
                    auto globalIndex = readUint16(ins[ip+1 .. $]);
                    this.currentFrame().ip += 2;

                    auto err = this.push(this.globals[globalIndex]);
                    if(err !is null)
                        return err;

                    break;

                case OPCODE.OpSetGlobal:
                    auto globalIndex = readUint16(ins[ip+1 .. $]);
                    this.currentFrame().ip += 2;

                    this.globals[globalIndex] = this.pop();

                    break;
                
                case OPCODE.OpArray:
                    auto numElements = readUint16(ins[ip+1..$]);
                    this.currentFrame().ip += 2;

                    auto array = this.buildArray(this.sp - numElements, this.sp);
                    this.sp -= numElements;

                    auto err = this.push(array);
                    if(err !is null)
                        return err;

                    break;
                
                case OPCODE.OpHash:
                    auto numElements = to!size_t(readUint16(ins[ip+1..$]));
                    this.currentFrame().ip += 2;
                
                    auto hash = this.buildHash(this.sp-numElements, this.sp);
                    if(hash.isNull)
                        return new Error(format("unusable as hash key"));
                    
                    this.sp -= numElements;

                    auto err = this.push(hash);
                    if(err !is null) 
                        return err;
                    
                    break;
                case OPCODE.OpIndex:
                    auto index = this.pop();
                    auto left = this.pop();

                    auto err = this.executeIndexExpression(left, index);
                    if(err !is null)
                        return err;
                    break;

                case OPCODE.OpCall:
                    auto numArgs = readUint8(ins[ip+1..$]);
                    this.currentFrame().ip += 1;

                    auto err = this.executeCall(numArgs);
                    if(err !is null)
                        return err;

                    break;
                case OPCODE.OpReturn:
                    auto frame = this.popFrame();
                    this.sp = frame.basePtr - 1;

                    auto err = this.push(NULL);
                    if(err !is null)
                        return err;

                    break;
                case OPCODE.OpReturnValue:
                    auto returnValue = this.pop();

                    auto frame = this.popFrame();
                    this.sp = frame.basePtr - 1;

                    auto err = this.push(returnValue);
                    if(err !is null)
                        return err;

                    break;

                case OPCODE.OpGetLocal:
                    auto localIndex = readUint8(ins[ip+1..$]);
                    this.currentFrame().ip += 1;

                    auto frame = this.currentFrame();

                    auto err = this.push(this.stack[frame.basePtr + localIndex]);
                    if (err !is null)                    
                        return err;

                    break;
                case OPCODE.OpSetLocal:
                    auto localIndex = readUint8(ins[ip+1..$]);
                    this.currentFrame().ip += 1;

                    auto frame = this.currentFrame();

                    this.stack[frame.basePtr + localIndex] = this.pop();

                    break;
                case OPCODE.OpGetBuiltin:
                    auto builtinIndex = readUint8(ins[ip+1..$]);
                    this.currentFrame().ip += 1;

                    auto definition = builtins[builtinIndex];
                    auto err = this.push(definition.builtin);
                    if(err !is null)
                        return err;

                    break;
                case OPCODE.OpClosure:
                    auto constIndex = readUint16(ins[ip+1..$]);
                    const numFree = readUint8(ins[ip+3..$]);
                    this.currentFrame().ip += 3;
                    
                    auto err = this.pushClosure(constIndex, numFree);
                    if(err !is null)
                        return err;

                    break;
                case OPCODE.OpGetFree:
                    auto freeIndex = readUint8(ins[ip+1..$]);
                    this.currentFrame().ip += 1;

                    auto currentClosure = this.currentFrame().cl;
                    auto err = this.push(currentClosure.free[freeIndex]);
                    if(err !is null)
                        return err;

                    break;
                case OPCODE.OpCurrentClosure:
                    auto currentClosure = this.currentFrame().cl;

                    auto err = this.push(currentClosure);
                    if(err !is null)
                        return err;
                    break;
            }
        }

        return null;
    }

    ///
    Error pushClosure(int constIndex, int numFree) {
        auto constant = this.constants[constIndex];

        auto func = cast(CompiledFunction) constant;
        if(func is null)
            return new Error(format("not a function: %s", constant));
        
        auto free = new Objekt[numFree];
        for(size_t i = 0; i < numFree; i++) {
            free[i] = this.stack[this.sp - numFree + i];
        }
        this.sp = this.sp - numFree;

        auto closure = new Closure(func);
        closure.free = free;

        return this.push(closure);
    }

    ///
    Error executeCall(int numArgs) {
        auto callee =  this.stack[this.sp - 1 - numArgs];
        switch(callee.type()) {
            case ObjectType.CLOSURE:
                return this.callClosure(cast(Closure)callee, numArgs);
            case ObjectType.BUILTIN:
                return this.callBuiltin(cast(BuiltIn)callee, numArgs);
            default:
                return new Error(format("calling non-function and non-built-in"));
        }
    }

    ///
    Error callBuiltin(BuiltIn builtin, int numArgs) {
        auto args = this.stack[this.sp - numArgs .. this.sp];

        auto result = builtin.fxn(args);
        this.sp = this.sp - numArgs - 1;

        if(result !is null)
            this.push(result);
        else
            this.push(NULL);

        return null;
    }

    ///
    Error callClosure(Closure cl, int numArgs) {
        if(numArgs != cl.fn.numParams)
            return new Error(format("wrong number of arguments: want=%d, got=%d",
                        cl.fn.numParams, numArgs));

        auto frame = new Frame(cl, cast(int) this.sp - numArgs);
        this.pushFrame(frame);

        this.sp = frame.basePtr + cl.fn.numLocals;

        return null;
    }

    ///
    Error executeIndexExpression(Objekt left, Objekt index) {
        if(left.type() == ObjectType.ARRAY && index.type() == ObjectType.INTEGER) 
            return this.executeArrayIndex(left, index);
        else if(left.type() == ObjectType.HASH)
            return this.executeHashIndex(left, index);
        else
            return new Error(format("index operator not supported: %s", left.type()));
    }

    ///
    Error executeArrayIndex(Objekt array, Objekt index) {
        auto arrayObject = cast(Array) array;
        auto i = (cast(Integer) index).value;
        auto max = cast(long) arrayObject.elements.length - 1;
        
        if(i < 0 || i > max) 
            return this.push(NULL);
        
        return this.push(arrayObject.elements[i]);
    }

    ///
    Error executeHashIndex(Objekt hash, Objekt index) {
        auto hashObject = cast(Hash) hash;
        auto key = cast(Hashable) index;
        if (key is null)
            return new Error(format("unusable as hash key: %s", index.type()));
        
        if(key.hashKey() !in hashObject.pairs)
            return this.push(NULL);

        auto pair = hashObject.pairs[key.hashKey()];

        return this.push(pair.value);
    }

    ///
    Nullable!Hash buildHash(size_t startIndex, size_t endIndex) {
        auto hashedPairs = (HashPair[HashKey]).init;
        auto result = Nullable!Hash();

        for(size_t i = startIndex; i < endIndex; i += 2) {
            auto key = this.stack[i];
            auto value = this.stack[i+1];

            auto hashKey = cast(Hashable) key;
            if(hashKey is null)
                return result;

            hashedPairs[hashKey.hashKey()] = HashPair(key, value);
        }

        result = new Hash(hashedPairs);
        return result;
    }

    ///
    Objekt buildArray(size_t startIndex, size_t endIndex) {
        auto elements = new Objekt[endIndex-startIndex];
        for(size_t i = startIndex; i < endIndex; ++i) {
            elements[i-startIndex] = this.stack[i];
        }

        return new Array(elements);
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
        else if(operand.inspect() == NULL.inspect()) return this.push(TRUE);
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
        else if(leftType == ObjectType.STRING && rightType == ObjectType.STRING) {
            return this.executeBinaryStringOperation(op, left, right);
        }

        return new Error(format("unsupported types for binary operation: %s %s",
                            leftType, rightType));
    }

    ///
    Error executeBinaryStringOperation(OPCODE op, Objekt left, Objekt right) {
        if(op != OPCODE.OpAdd)
            return new Error(format("unknown string operator: %d", op));

        auto leftValue = (cast(String) left).value;
        auto rightValue = (cast(String) right).value;

        return this.push(new String(leftValue ~ rightValue));
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
        if(this.sp >= STACK_SIZE)
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
    if(obj.type() == ObjectType.BOOLEAN) return (cast(Boolean) obj).value;
    else if(obj.type() == ObjectType.NULL) return false;
    else return true;
}