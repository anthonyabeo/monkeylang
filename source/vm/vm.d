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
            }
        }

        return null;
    }

    ///
    Error push(Objekt obj) {
        if(this.sp >= StackSize)
            return new Error(format("stackoverflow"));

        this.stack[this.sp] = obj;
        this.sp++;

        return null;
    }
}