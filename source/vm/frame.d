module vm.frame;

import code.code;
import objekt.objekt;


/+++/
class Frame {
    CompiledFunction fn;    /// funtion to be executed
    int ip;                 /// instruction ptr;
    int basePtr;            /// base ptr;

    /+++/
    this(CompiledFunction fn, int basePtr) {
        this.fn = fn;
        this.ip = -1;
        this.basePtr = basePtr;
    }

    /+++/
    Instructions instructions() {
        return this.fn.instructions;
    }
}