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
    OpAdd,
    OpSub,
    OpDiv,
    OpMul,
    OpPop,
    OpTrue,
    OpFalse,
    OpEqual,
    OpNotEqual,
    OpGreaterThan,
    OpMinus,
    OpBang,
    OpJumpNotTruthy,
    OpJump,
    OpNull,
    OpGetGlobal,
    OpSetGlobal,
    OpArray,
    OpHash,
}

Definition[OPCODE] definitions; /// definitions

///
static this() {
    definitions = [
        OPCODE.OpConstant : new Definition("OpConstant", [2]),
        OPCODE.OpAdd : new Definition("OpAdd", []),
        OPCODE.OpSub : new Definition("OpSub", []),
        OPCODE.OpMul : new Definition("OpMul", []),
        OPCODE.OpDiv : new Definition("OpDiv", []),
        OPCODE.OpPop : new Definition("OpPop", []),
        OPCODE.OpTrue : new Definition("OpTrue", []),
        OPCODE.OpFalse : new Definition("OpFalse", []), 
        OPCODE.OpEqual : new Definition("OpEqual", []),
        OPCODE.OpNotEqual : new Definition("OpNotEqual", []),
        OPCODE.OpGreaterThan : new Definition("OpGreaterThan", []),
        OPCODE.OpMinus : new Definition("OpMinus", []),
        OPCODE.OpBang : new Definition("OpBang", []),
        OPCODE.OpJump : new Definition("OpJump", [2]),
        OPCODE.OpJumpNotTruthy : new Definition("OpJumpNotTruthy", [2]),
        OPCODE.OpNull : new Definition("OpNull", []),
        OPCODE.OpGetGlobal : new Definition("OpGetGlobal", [2]),
        OPCODE.OpSetGlobal : new Definition("OpSetGlobal", [2]),
        OPCODE.OpArray : new Definition("OpArray", [2]),
        OPCODE.OpHash : new Definition("OpHash", [2]),
    ];
}

/+++++++++++++++++++++++++++++++++++++++++++
 +   Returns the Definition associated with the opcode provided.   
 +   Params:
 +      op = opcode
 +
 +   Return:
 +++++++++++++++++++++++++++++++++++++++++++++/
Definition lookUp(ubyte op) {
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
    ++++++++++++++++++++++++++++++++++++++++++++/
    this(string name, int[] opWidth) {
        this.name = name;
        this.operandWidths = opWidth;
    }
}

///
ubyte[] make(Opcode op, size_t[] operands...) {
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

/++
 +
 +
 +/
string asString(Instructions ins) {
    string o;
    
    size_t i = 0;
    while(i < ins.length) {
        auto def = lookUp(ins[i]);
        if(def is null) {
            o ~= format("ERROR: %s\n", def);
            continue;
        }

        auto result = readOperands(def, ins[i+1..$]);
        auto operands = result[0], read = result[1];

        o ~= format("%04d %s\n", i, fmtInstruction(ins, def, operands));

        i += 1 + read;
    }

    return o;
}

///
string fmtInstruction(Instructions ins, Definition def, int[] operands) {
    auto operandCount = def.operandWidths.length;
    if(operands.length != operandCount) {
        return format("ERROR: operand len %d does not match defined %d\n",
                        operands.length, operandCount);
    }
        
    switch(operandCount) {
        case 0:
            return def.name;
        case 1:
            return format("%s %d", def.name, operands[0]);
        default:
            return format("ERROR: unhandled operandCount for %s\n", def.name);
    }
        
}

///
Tuple!(int[], int) readOperands(Definition def, Instructions ins) {
    auto operands = new int[def.operandWidths.length];
    auto offset = 0;
    foreach(i, width; def.operandWidths) {
        switch(width) {
            case 2:
                operands[i] = readUint16(ins[offset .. $]);
                offset += width;
                break;
            default:
                break;
        }
    }

    return tuple(operands, offset);
}

/**
	Generate the 16-bit numerical value from an array of two bytes
	in a big-endian format.

	Params:
		data = an immutable array of bytes of size 2 in big endian format;

	Returns:
		the 16-bit numerical value of this array representation.
*/
auto readUint16(ubyte[] data) 
{
	return data[0] << 8  | 
	       data[1];
}