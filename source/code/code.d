module code.code;

import std.conv;
import std.string;
import std.typecons;
import std.bitmanip;
import std.stdio;

alias Instructions = ubyte[];
alias Opcode = ubyte;

/// OPCODES
enum OPCODE : Opcode {
    OpConstant,
}

Definition[OPCODE] definitions; /// definitions

///
static this() {
    definitions = [
        OPCODE.OpConstant : new Definition("OpConstant", [2]),
    ];
}

/+++++++++++++++++++++++++++++++++++++++++++
 +   Returns the Definition associated with the opcode provided.   
 +   Params:
 +      op = opcode
 +
 +   Return:
 +/
const(Definition) lookUp(ubyte op) {
    if(cast(OPCODE)op !in definitions)
        return null;

    return definitions[cast(OPCODE)op];
}

/+++/
class Definition {
    string name;            /// name
    int[] operandWidths;    /// width of operands

    /+++++++++++++++++++++++++++++++++++++++++++
    +   Constructor.   
    +   Params:
    +      name = 
    +      opWidth = 
    +/
    this(string name, int[] opWidth) {
        this.name = name;
        this.operandWidths = opWidth;
    }
}

///
ubyte[] make(Opcode op, int[] operands...) {
    ubyte[] instruction = [];

    auto def = definitions[cast(OPCODE) op];
    if(def is null)
        return instruction;
    
    size_t instLen = 1;
    foreach(w; def.operandWidths) {
        instLen += w;
    }

    instruction = new ubyte[instLen];
    instruction[0] = cast(byte) op;

    size_t offset = 1;
    foreach(i, o; operands) {
        immutable width = def.operandWidths[i];
        switch (width) {
            case 2:
                auto results = nativeToBigEndian(cast(ushort) o);
                foreach(e; results) {
                    instruction[offset++] = e;
                }
                break;
            default:
                break;
        }
    }

    return instruction;
}